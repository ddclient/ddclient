use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

my $plain = ['Content-Type' => 'text/plain'];

httpd()->run();

my @test_cases = (
    {
        desc => 'subdomain IPv4 and IPv6 — two separate requests',
        cfg => {'test.example.com' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $plain, ["ok"]],
            [200, $plain, ["ok"]],
        ],
        wantrecap => {'test.example.com' => {
            'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
            'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 requests: A then AAAA');
            my %q0 = $reqs[0]->uri()->query_form();
            my %q1 = $reqs[1]->uri()->query_form();
            is($reqs[0]->uri()->path(), '/set_ddns', 'request 0 path');
            is($reqs[1]->uri()->path(), '/set_ddns', 'request 1 path');
            is($q0{type},        'A',           'first request type A');
            is($q0{domain},      'example.com', 'domain');
            is($q0{subDomain},   'test',        'subDomain');
            is($q0{ip},          '192.0.2.1',   'IPv4 address');
            is($q0{containRoot}, 'false',        'containRoot false for subdomain');
            is($q1{type},        'AAAA',         'second request type AAAA');
            is($q1{ip},          '2001:db8::1',  'IPv6 address');
        },
    },
    {
        desc => 'root domain sets containRoot=true and omits subDomain',
        cfg => {'example.com' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.2',
        }},
        responses => [[200, $plain, ["ok"]]],
        wantrecap => {'example.com' => {
            'status-ipv4' => 'good', 'ipv4' => '192.0.2.2',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['example.com'], msg => qr/IPv4 address set to 192\.0\.2\.2/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, '1 request');
            my %q = $reqs[0]->uri()->query_form();
            is($q{containRoot}, 'true', 'containRoot true for root domain');
            ok(!exists($q{subDomain}), 'no subDomain for root domain');
        },
    },
    {
        desc => 'on-root-domain sets containRoot=true for subdomain',
        cfg => {'test.example.com' => {
            protocol         => 'dynadot',
            password         => 'secret',
            zone             => 'example.com',
            server           => httpd()->endpoint(),
            ttl              => 300,
            'on-root-domain' => 1,
            wantipv4         => '192.0.2.3',
        }},
        responses => [[200, $plain, ["ok"]]],
        wantrecap => {'test.example.com' => {
            'status-ipv4' => 'good', 'ipv4' => '192.0.2.3',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.3/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            my %q = $reqs[0]->uri()->query_form();
            is($q{containRoot}, 'true',   'containRoot true when on-root-domain set');
            is($q{subDomain},   'test',   'subDomain still present');
        },
    },
    {
        desc => 'provider error response sets status to failed',
        cfg => {'test.example.com' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.4',
        }},
        responses => [[200, $plain, ["fail: invalid password"]]],
        wantrecap => {'test.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['test.example.com'], msg => qr/server said: fail: invalid password/},
        ],
    },
    {
        desc => 'unexpected response body sets status to failed',
        cfg => {'test.example.com' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.5',
        }},
        responses => [[200, $plain, ["something unexpected"]]],
        wantrecap => {'test.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['test.example.com'], msg => qr/server said/},
        ],
    },
    {
        desc => 'HTTP error sets status to failed',
        cfg => {'test.example.com' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.6',
        }},
        responses => [[500, $plain, ["internal server error"]]],
        wantrecap => {'test.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['test.example.com'], msg => qr/500 Internal Server Error/},
        ],
    },
    {
        desc => 'zone mismatch fails before any request',
        cfg => {'test.example.net' => {
            protocol => 'dynadot',
            password => 'secret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            ttl      => 300,
            wantipv4 => '192.0.2.7',
        }},
        responses => [],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['test.example.net'], msg => qr/does not end with the 'zone' value/},
        ],
    },
);

for my $tc (@test_cases) {
    subtest($tc->{desc} => sub {
        local $ddclient::globals{debug}   = 1;
        local $ddclient::globals{verbose} = 1;
        local %ddclient::config  = %{$tc->{cfg}};
        local %ddclient::recap;

        httpd()->reset(@{$tc->{responses}});

        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        {
            local $ddclient::_l = $l;
            ddclient::nic_dynadot_update(undef, sort(keys(%{$tc->{cfg}})));
        }

        my @reqs = httpd()->reset();

        is_deeply(\%ddclient::recap, $tc->{wantrecap}, 'recap matches')
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names  => ['*got', '*want']));

        subtest('logs' => sub {
            my @got  = @{$l->{logs}};
            my @want = @{$tc->{wantlogs} // []};
            for my $i (0..$#want) {
                last if $i >= @got;
                subtest("log $i" => sub {
                    is($got[$i]{label}, $want[$i]{label}, 'label');
                    is_deeply($got[$i]{ctx}, $want[$i]{ctx}, 'context');
                    like($got[$i]{msg}, $want[$i]{msg}, 'message');
                });
            }
            my @unexpected = @got[@want..$#got];
            ok(@unexpected == 0, 'no unexpected logs')
                or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
            my @missing = @want[@got..$#want];
            ok(@missing == 0, 'no missing logs')
                or diag(ddclient::repr(\@missing, Names => ['*missing']));
        });

        $tc->{check_reqs}->(@reqs) if $tc->{check_reqs};
    });
}

done_testing();
