use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
use MIME::Base64;
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

httpd()->run(sub {
    my ($req) = @_;
    diag('==============================================================================');
    diag("Test server received request:\n" . $req->as_string());
    return undef if $req->uri()->path() eq '/control';
    my $wantauthn = 'Basic ' . encode_base64('username:password', '');
    return [401, [@$textplain, 'www-authenticate' => 'Basic realm="realm", charset="UTF-8"'],
            ['authentication required']] if ($req->header('authorization') // '') ne $wantauthn;
    return [400, $textplain, ['invalid method: ' . $req->method()]] if $req->method() ne 'GET';
    return undef;
});

my @test_cases = (
    {
        desc => 'IPv4 only, good',
        cfg => {'myhome.dynu.net' => {wantipv4 => '192.0.2.1'}},
        resp => ['good'],
        wantquery => 'hostname=myhome.dynu.net&myip=192.0.2.1',
        wantrecap => {
            'myhome.dynu.net' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhome.dynu.net'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv6 only, good',
        cfg => {'myhome.dynu.net' => {wantipv6 => '2001:db8::1'}},
        resp => ['good'],
        wantquery => 'hostname=myhome.dynu.net&myip=no&myipv6=2001:db8::1',
        wantrecap => {
            'myhome.dynu.net' => {'status-ipv6' => 'good', 'ipv6' => '2001:db8::1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhome.dynu.net'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'dual-stack IPv4+IPv6, good',
        cfg => {'myhome.dynu.net' => {wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::1'}},
        resp => ['good'],
        wantquery => 'hostname=myhome.dynu.net&myip=192.0.2.1&myipv6=2001:db8::1',
        wantrecap => {
            'myhome.dynu.net' => {
                'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhome.dynu.net'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['myhome.dynu.net'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'nochg treated as good',
        cfg => {'myhome.dynu.net' => {wantipv4 => '192.0.2.1'}},
        resp => ['nochg'],
        wantquery => 'hostname=myhome.dynu.net&myip=192.0.2.1',
        wantrecap => {
            'myhome.dynu.net' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'WARNING', ctx => ['myhome.dynu.net'], msg => qr/nochg/},
            {label => 'SUCCESS', ctx => ['myhome.dynu.net'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'error response',
        cfg => {'myhome.dynu.net' => {wantipv4 => '192.0.2.1'}},
        resp => ['badauth'],
        wantquery => 'hostname=myhome.dynu.net&myip=192.0.2.1',
        wantrecap => {
            'myhome.dynu.net' => {'status-ipv4' => 'badauth'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['myhome.dynu.net'], msg => qr/badauth/},
        ],
    },
    {
        desc => 'zone: hostname+alias construction',
        cfg => {'host.example.com' => {zone => 'example.com', wantipv4 => '192.0.2.1'}},
        resp => ['good'],
        wantquery => 'hostname=example.com&alias=host&myip=192.0.2.1',
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'zone mismatch: hostname outside zone',
        cfg => {'host.other.com' => {zone => 'example.com', wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.other.com'], msg => qr/does not end with the zone/},
        ],
    },
);

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    diag('==============================================================================');
    local $ddclient::globals{debug} = 1;
    local $ddclient::globals{verbose} = 1;
    my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
    local %ddclient::config;
    local %ddclient::recap;
    $ddclient::config{$_} = {
        login    => 'username',
        password => 'password',
        server   => httpd()->endpoint(),
        %{$tc->{cfg}{$_}},
    } for keys(%{$tc->{cfg}});
    httpd()->reset([200, $textplain, [map("$_\n", @{$tc->{resp}})]]) if defined $tc->{resp};
    {
        local $ddclient::_l = $l;
        ddclient::nic_dynu_update(undef, sort(keys(%{$tc->{cfg}})));
    }
    my @requests = httpd()->reset();
    if (defined $tc->{wantquery}) {
        is(scalar(@requests), 1, "$tc->{desc}: single update request");
        my $req = shift(@requests);
        is($req->uri()->path(), '/nic/update', "$tc->{desc}: request path");
        is($req->uri()->query(), $tc->{wantquery}, "$tc->{desc}: request query");
    } else {
        is(scalar(@requests), 0, "$tc->{desc}: no requests sent");
    }
    is_deeply(\%ddclient::recap, $tc->{wantrecap}, "$tc->{desc}: recap")
        or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                               Names => ['*got', '*want']));
    $tc->{wantlogs} //= [];
    subtest("$tc->{desc}: logs" => sub {
        my @got = @{$l->{logs}};
        my @want = @{$tc->{wantlogs}};
        for my $i (0..$#want) {
            last if $i >= @got;
            my $got = $got[$i];
            my $want = $want[$i];
            subtest("log $i" => sub {
                is($got->{label}, $want->{label}, "label matches");
                is_deeply($got->{ctx}, $want->{ctx}, "context matches");
                like($got->{msg}, $want->{msg}, "message matches");
            }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
        }
        my @unexpected = @got[@want..$#got];
        ok(@unexpected == 0, "no unexpected logs")
            or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
        my @missing = @want[@got..$#want];
        ok(@missing == 0, "no missing logs")
            or diag(ddclient::repr(\@missing, Names => ['*missing']));
    });
}

done_testing();
