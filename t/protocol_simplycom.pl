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
    my $wantauthn = 'Basic ' . encode_base64('S123456:apikey', '');
    return [401, [@$textplain, 'www-authenticate' => 'Basic realm="realm", charset="UTF-8"'],
            ['authentication required']] if ($req->header('authorization') // '') ne $wantauthn;
    return [400, $textplain, ['invalid method: ' . $req->method()]] if $req->method() ne 'GET';
    return undef;
});

my @test_cases = (
    {
        desc => 'IPv4, good',
        cfg => {'test.example.com' => {wantipv4 => '192.0.2.1', zone => 'example.com'}},
        resp => [['good 192.0.2.1']],
        wantqueries => ['hostname=test.example.com&myip=192.0.2.1&domain=example.com'],
        wantrecap => {
            'test.example.com' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                                   'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
    },
    {
        desc => 'IPv4, nochg',
        cfg => {'test.example.com' => {wantipv4 => '192.0.2.1', zone => 'example.com'}},
        resp => [['nochg 192.0.2.1']],
        wantqueries => ['hostname=test.example.com&myip=192.0.2.1&domain=example.com'],
        wantrecap => {
            'test.example.com' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                                   'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/skipped.*already set to 192\.0\.2\.1/},
        ],
    },
    {
        desc => 'IPv4, failure',
        cfg => {'test.example.com' => {wantipv4 => '192.0.2.1', zone => 'example.com'}},
        resp => [['nohost']],
        wantqueries => ['hostname=test.example.com&myip=192.0.2.1&domain=example.com'],
        wantrecap => {
            'test.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['test.example.com'], msg => qr/server said: nohost/},
        ],
    },
    {
        desc => 'IPv6, good',
        cfg => {'test.example.com' => {wantipv6 => '2001:db8::1', zone => 'example.com'}},
        resp => [['good 2001:db8::1']],
        wantqueries => ['hostname=test.example.com&myip=2001:db8::1&domain=example.com'],
        wantrecap => {
            'test.example.com' => {'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                                   'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
    },
    {
        desc => 'IPv4 and IPv6, two separate requests',
        cfg => {'test.example.com' => {
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
            zone => 'example.com',
        }},
        resp => [['good 192.0.2.1'], ['good 2001:db8::1']],
        wantqueries => [
            'hostname=test.example.com&myip=192.0.2.1&domain=example.com',
            'hostname=test.example.com&myip=2001:db8::1&domain=example.com',
        ],
        wantrecap => {
            'test.example.com' => {
                'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
    },
    {
        desc => 'zone is optional',
        cfg => {'test.example.com' => {wantipv4 => '192.0.2.1'}},
        resp => [['good 192.0.2.1']],
        wantqueries => ['hostname=test.example.com&myip=192.0.2.1'],
        wantrecap => {
            'test.example.com' => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                                   'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['test.example.com'], msg => qr/IPv4/},
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
        protocol => 'simply.com',
        login => 'S123456',
        password => 'apikey',
        server => httpd()->endpoint(),
        %{$tc->{cfg}{$_}},
    } for keys(%{$tc->{cfg}});
    httpd()->reset(map { [200, $textplain, [map("$_\n", @$_)]] } @{$tc->{resp}});
    {
        local $ddclient::_l = $l;
        ddclient::nic_simplycom_update(undef, sort(keys(%{$tc->{cfg}})));
    }
    my @requests = httpd()->reset();
    is(scalar(@requests), scalar(@{$tc->{wantqueries}}),
       "$tc->{desc}: number of update requests");
    for my $i (0..$#{$tc->{wantqueries}}) {
        last if $i >= @requests;
        is($requests[$i]->uri()->path(), '/nic/update',
           "$tc->{desc}: request $i path");
        is($requests[$i]->uri()->query(), $tc->{wantqueries}[$i],
           "$tc->{desc}: request $i query");
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
