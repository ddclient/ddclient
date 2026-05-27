use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('scaleway');

my $j = ['Content-Type' => 'application/json'];

sub records_resp {
    encode_json({records => []});
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({records => [{name => 'host', type => 'A', data => '192.0.2.1', ttl => 300}]})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'exactly 1 PATCH request');
            is($reqs[0]->method(), 'PATCH', 'request is PATCH');
            like($reqs[0]->uri()->path(), qr{/dns-zones/example\.com/records}, 'path correct');
            my $body = decode_json($reqs[0]->content());
            is($body->{changes}[0]{set}{name},             'host',      'set name is subdomain');
            is($body->{changes}[0]{set}{type},             'A',         'set type is A');
            is($body->{changes}[0]{set}{records}[0]{data}, '192.0.2.1', 'record data correct');
            is($body->{changes}[0]{set}{records}[0]{ttl},  300,         'record ttl correct');
        },
    },
    {
        desc => 'IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [encode_json({records => [{name => 'host', type => 'AAAA', data => '2001:db8::1', ttl => 300}]})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6.*2001:db8::1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'exactly 1 PATCH request');
            my $body = decode_json($reqs[0]->content());
            is($body->{changes}[0]{set}{type},             'AAAA',       'set type is AAAA');
            is($body->{changes}[0]{set}{records}[0]{data}, '2001:db8::1','record data correct');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [encode_json({records => [{name => 'host', type => 'A',    data => '192.0.2.1',   ttl => 300}]})]],
            [200, $j, [encode_json({records => [{name => 'host', type => 'AAAA', data => '2001:db8::1', ttl => 300}]})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
            'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 PATCH requests: one per IP version');
            is($reqs[0]->method(), 'PATCH', 'first is PATCH');
            is($reqs[1]->method(), 'PATCH', 'second is PATCH');
        },
    },
    {
        desc => 'apex domain (zone == hostname)',
        cfg => {'example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({records => [{name => '@', type => 'A', data => '192.0.2.1', ttl => 300}]})]],
        ],
        wantrecap => {'example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            my $body = decode_json($reqs[0]->content());
            is($body->{changes}[0]{set}{name}, '@', 'apex uses @ as subdomain');
        },
    },
    {
        desc => 'API error response',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'badtoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [401, $j, [encode_json({message => 'Invalid authentication credentials'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 401.*Invalid authentication/},
        ],
    },
    {
        desc => 'HTTP 500 error',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [500, $j, [encode_json({message => 'Internal Server Error'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 500/},
        ],
    },
    {
        desc => 'correct X-Auth-Token header sent',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'supersecretkey',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({records => [{name => 'host', type => 'A', data => '192.0.2.1', ttl => 300}]})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is($reqs[0]->header('X-Auth-Token'), 'supersecretkey',
                'X-Auth-Token header is correct');
        },
    },
    {
        desc => 'no-op: no IPs requested',
        cfg => {'host.example.com' => {
            protocol => 'scaleway',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
        }},
        responses => [],
        wantrecap => {},
        wantlogs  => [],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 0, 'no requests made when no IPs requested');
        },
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
            ddclient::nic_scaleway_update(undef, sort(keys(%{$tc->{cfg}})));
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
