use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('1984');

my $j = ['Content-Type' => 'application/json'];

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({ok => JSON::PP::true, msg => 'updated', ip => '192.0.2.1'})]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, '1 request for IPv4 update');
            my $q = $reqs[0]->uri()->query();
            like($q, qr/apikey=myapikey/,            'apikey present');
            like($q, qr/domain=myhost\.example\.com/, 'domain present');
            like($q, qr/ip=192\.0\.2\.1/,             'ip present');
        },
    },
    {
        desc => 'IPv4 unaltered (already up to date)',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({ok => JSON::PP::true, msg => 'Your IP is unaltered', ip => '192.0.2.1'})]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/already set/},
        ],
    },
    {
        desc => 'IPv6 success',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [encode_json({ok => JSON::PP::true, msg => 'updated', ip => '2001:db8::1'})]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6.*2001:db8::1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, '1 request for IPv6 update');
            my $q = $reqs[0]->uri()->query();
            like($q, qr/ip=2001/, 'ip param contains IPv6 address');
        },
    },
    {
        desc => 'dual-stack sends two separate requests',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [encode_json({ok => JSON::PP::true, msg => 'updated', ip => '192.0.2.1'})]],
            [200, $j, [encode_json({ok => JSON::PP::true, msg => 'updated', ip => '2001:db8::1'})]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6.*2001:db8::1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 requests for dual-stack update');
        },
    },
    {
        desc => 'server returns ok:false',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'badkey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({ok => JSON::PP::false, msg => 'Invalid API key'})]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/Invalid API key/},
        ],
    },
    {
        desc => 'JSON decode failure',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, ["{not valid json}"]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/JSON decoding failure/},
        ],
    },
    {
        desc => 'HTTP error',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [500, $j, [encode_json({ok => JSON::PP::false, msg => 'server error'})]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/500/},
        ],
    },
    {
        desc => 'no wantipv4 or wantipv6, no request sent',
        cfg => {'myhost.example.com' => {
            protocol => '1984',
            server   => httpd()->endpoint(),
            password => 'myapikey',
        }},
        responses => [],
        wantrecap => {},
        wantlogs  => [],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 0, 'no requests sent');
        },
    },
);

for my $tc (@test_cases) {
    subtest($tc->{desc} => sub {
        local %ddclient::config = %{$tc->{cfg}};
        local %ddclient::recap;
        httpd()->reset(@{$tc->{responses}});
        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        {
            local $ddclient::_l = $l;
            ddclient::nic_1984_update(undef, sort(keys(%{$tc->{cfg}})));
        }
        my @reqs = httpd()->reset();
        is_deeply(\%ddclient::recap, $tc->{wantrecap}, 'recap matches')
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names => ['*got', '*want']));
        subtest('logs' => sub {
            my @got  = @{$l->{logs}};
            my @want = @{$tc->{wantlogs}};
            for my $i (0..$#want) {
                last if $i >= @got;
                my ($got, $want) = ($got[$i], $want[$i]);
                subtest("log $i" => sub {
                    is($got->{label},        $want->{label},  'label matches');
                    is_deeply($got->{ctx},   $want->{ctx},    'context matches');
                    like($got->{msg},        $want->{msg},    'message matches');
                }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
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
