use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

my $textplain = ['Content-Type' => 'text/plain'];

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $textplain, ["good 192.0.2.1\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.ddnss.de'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, '1 request');
            is($reqs[0]->uri()->path(), '/upd.php', 'correct path');
            my $q = $reqs[0]->uri()->query();
            like($q,   qr/key=myapikey/,          'key param present');
            like($q,   qr/host=myhost\.ddnss\.de/, 'host param present');
            like($q,   qr/\bip=192\.0\.2\.1\b/,   'ip param present');
            unlike($q, qr/\bip6=/,                 'no ip6 param');
        },
    },
    {
        desc => 'IPv6 success',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $textplain, ["good 2001:db8::1\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.ddnss.de'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, '1 request');
            is($reqs[0]->uri()->path(), '/upd.php', 'correct path');
            my $q = $reqs[0]->uri()->query();
            like($q,   qr/key=myapikey/,          'key param present');
            like($q,   qr/host=myhost\.ddnss\.de/, 'host param present');
            like($q,   qr/\bip6=/,                 'ip6 param present');
            unlike($q, qr/[&?]ip=/,                'no bare ip param');
        },
    },
    {
        desc => 'dual-stack success',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $textplain, ["good 192.0.2.1\n"]],
            [200, $textplain, ["good 2001:db8::1\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.ddnss.de'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['myhost.ddnss.de'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 requests (one per IP version)');
        },
    },
    {
        desc => 'server returns non-good response',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'badkey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $textplain, ["badauth\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.ddnss.de'], msg => qr/server said: badauth/},
        ],
    },
    {
        desc => 'HTTP error leaves recap with failed status',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [500, $textplain, ["internal server error\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.ddnss.de'], msg => qr/500/},
        ],
    },
    {
        desc => 'dual-stack partial success: IPv4 fails, IPv6 succeeds',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
            server   => httpd()->endpoint(),
            password => 'myapikey',
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $textplain, ["badauth\n"]],
            [200, $textplain, ["good 2001:db8::1\n"]],
        ],
        wantrecap => {'myhost.ddnss.de' => {
            'status-ipv4' => 'failed',
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'FAILED',  ctx => ['myhost.ddnss.de'], msg => qr/server said: badauth/},
            {label => 'SUCCESS', ctx => ['myhost.ddnss.de'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'no wantipv4 or wantipv6, no request sent',
        cfg => {'myhost.ddnss.de' => {
            protocol => 'ddnss',
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
            ddclient::nic_ddnss_update(undef, sort(keys(%{$tc->{cfg}})));
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
