use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;
use MIME::Base64;

httpd_required();

ddclient::load_json_support('glesys');

httpd()->run();

my $endpoint = httpd()->endpoint();

## Standard response factories

sub listrecords_ok {
    my ($host, $type, $recordid) = @_;
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        response => {
            status  => { code => 200, text => 'OK' },
            records => [
                { recordid => $recordid, host => $host, type => $type, data => '0.0.0.0', ttl => 3600 },
            ],
        },
    })]];
}

sub listrecords_empty {
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        response => {
            status  => { code => 200, text => 'OK' },
            records => [],
        },
    })]];
}

sub updaterecord_ok {
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        response => {
            status => { code => 200, text => 'OK' },
            record => { recordid => 12345 },
        },
    })]];
}

sub updaterecord_err {
    my ($text) = @_;
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        response => {
            status => { code => 500, text => $text // 'Internal error' },
        },
    })]];
}

## Helper to build a config entry
sub make_cfg {
    my (%extra) = @_;
    return {
        login    => 'CL12345',
        password => 'test-api-key',
        server   => $endpoint,
        zone     => 'example.com',
        %extra,
    };
}

## Helper to check Basic auth header
sub check_basic_auth {
    my ($req, $login, $password) = @_;
    my $expected = 'Basic ' . encode_base64("$login:$password", '');
    is($req->header('authorization'), $expected, 'Authorization header is correct Basic auth');
}

my @test_cases = (
    {
        desc     => 'IPv4, success',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv4 => '192.0.2.1') },
        responses => [
            listrecords_ok('myhost', 'A', 11111),
            updaterecord_ok(),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            { label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/ },
        ],
    },
    {
        desc     => 'IPv6, success',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv6 => '2001:db8::1') },
        responses => [
            listrecords_ok('myhost', 'AAAA', 22222),
            updaterecord_ok(),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            { label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6/ },
        ],
    },
    {
        desc     => 'dual-stack, both succeed',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::1') },
        responses => [
            listrecords_ok('myhost', 'A',    11111),
            updaterecord_ok(),
            listrecords_ok('myhost', 'AAAA', 22222),
            updaterecord_ok(),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            { label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/ },
            { label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6/ },
        ],
    },
    {
        desc     => 'record not found (empty records list)',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv4 => '192.0.2.1') },
        responses => [
            listrecords_empty(),
        ],
        wantrecap => {
            'myhost.example.com' => { 'status-ipv4' => 'failed' },
        },
        wantlogs => [
            { label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/no A record found for myhost in zone example\.com/ },
        ],
    },
    {
        desc     => 'updaterecord API error',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv4 => '192.0.2.1') },
        responses => [
            listrecords_ok('myhost', 'A', 11111),
            updaterecord_err('Permission denied'),
        ],
        wantrecap => {
            'myhost.example.com' => { 'status-ipv4' => 'failed' },
        },
        wantlogs => [
            { label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/updaterecord failed: Permission denied/ },
        ],
    },
    {
        desc     => 'HTTP error on listrecords',
        cfg      => { 'myhost.example.com' => make_cfg(wantipv4 => '192.0.2.1') },
        responses => [
            [401, ['Content-Type' => 'text/plain'], ['Unauthorized']],
        ],
        wantrecap => {
            'myhost.example.com' => { 'status-ipv4' => 'failed' },
        },
        wantlogs => [
            { label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/401/ },
        ],
    },
);

for my $tc (@test_cases) {
    subtest($tc->{desc} => sub {
        local $ddclient::globals{debug}   = 1;
        local $ddclient::globals{verbose} = 1;
        local $ddclient::globals{exec}    = 1;

        httpd()->reset(@{$tc->{responses}});

        local %ddclient::config = %{$tc->{cfg}};
        local %ddclient::recap;

        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        {
            local $ddclient::_l = $l;
            ddclient::nic_glesys_update(undef, sort(keys(%{$tc->{cfg}})));
        }

        my @reqs = httpd()->reset();

        ## Verify Basic auth on each request
        for my $req (@reqs) {
            check_basic_auth($req, 'CL12345', 'test-api-key');
        }

        is_deeply(\%ddclient::recap, $tc->{wantrecap}, "$tc->{desc}: recap")
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names  => ['*got', '*want']));

        $tc->{wantlogs} //= [];
        subtest("$tc->{desc}: logs" => sub {
            my @got  = @{$l->{logs}};
            my @want = @{$tc->{wantlogs}};
            for my $i (0 .. $#want) {
                last if $i >= @got;
                my $got  = $got[$i];
                my $want = $want[$i];
                subtest("log $i" => sub {
                    is($got->{label}, $want->{label}, 'label matches');
                    is_deeply($got->{ctx}, $want->{ctx}, 'context matches');
                    like($got->{msg}, $want->{msg}, 'message matches');
                }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
            }
            my @unexpected = @got[@want .. $#got];
            ok(@unexpected == 0, 'no unexpected logs')
                or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
            my @missing = @want[@got .. $#want];
            ok(@missing == 0, 'no missing logs')
                or diag(ddclient::repr(\@missing, Names => ['*missing']));
        });
    });
}

done_testing();
