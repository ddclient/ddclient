use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('dnspod');

my $json_ct = ['Content-Type' => 'application/json'];

sub parse_form {
    my ($body) = @_;
    my %params;
    for (split /&/, $body // '') {
        my ($k, $v) = split /=/, $_, 2;
        $v =~ s/\+/ /g;
        $v =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
        $params{$k} = $v;
    }
    return %params;
}

httpd()->run(sub {
    my ($req) = @_;
    return undef if $req->uri()->path() eq '/control';
    return [405, $textplain, ['unexpected method']] unless $req->method() eq 'POST';
    my %p = parse_form($req->content());
    my $token = $p{login_token} // '';
    my $path  = $req->uri()->path();

    if ($path eq '/Record.List') {
        # Simulate auth failure
        return [200, $json_ct, [encode_json({
            status => {code => '6', message => 'login failed'},
        })]] if $token =~ /^badauth,/;

        # Simulate no matching records
        return [200, $json_ct, [encode_json({
            status  => {code => '1', message => 'Action completed successful'},
            records => [],
        })]] if $token =~ /^norecord,/;

        # Return one matching record
        return [200, $json_ct, [encode_json({
            status  => {code => '1', message => 'Action completed successful'},
            records => [{id => '99999', line => 'Default', value => '0.0.0.0',
                         type => $p{record_type}}],
        })]];
    } elsif ($path eq '/Record.Ddns') {
        # Simulate DDNS update failure
        return [200, $json_ct, [encode_json({
            status => {code => '8', message => 'record not found'},
        })]] if $token =~ /^ddfail,/;

        return [200, $json_ct, [encode_json({
            status => {code => '1', message => 'Action completed successful'},
            record => {id => '99999', value => $p{value}},
        })]];
    }
    return [400, $textplain, ['unexpected path: ' . $path]];
});

my $ep = httpd()->endpoint();

my @test_cases = (
    {
        desc => 'IPv4, success with explicit zone',
        cfg  => {'host.example.com' => {
            login    => '12345',
            password => 'mytoken',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv6, success with explicit zone',
        cfg  => {'host.example.com' => {
            login    => '12345',
            password => 'mytoken',
            zone     => 'example.com',
            server   => $ep,
            wantipv6 => '2001:db8::1',
        }},
        wantrecap => {'host.example.com' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'IPv4 and IPv6, both succeed',
        cfg  => {'host.example.com' => {
            login    => '12345',
            password => 'mytoken',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'IPv4, success without zone (auto-split)',
        cfg  => {'host.example.com' => {
            login    => '12345',
            password => 'mytoken',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'Record.List auth failure',
        cfg  => {'host.example.com' => {
            login    => 'badauth',
            password => 'token',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs  => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Record\.List.*login failed/},
        ],
    },
    {
        desc => 'Record.List no records found',
        cfg  => {'host.example.com' => {
            login    => 'norecord',
            password => 'token',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs  => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/no A record found/},
        ],
    },
    {
        desc => 'Record.Ddns update failure',
        cfg  => {'host.example.com' => {
            login    => 'ddfail',
            password => 'token',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs  => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Record\.Ddns.*record not found/},
        ],
    },
    {
        desc => 'hostname does not match zone',
        cfg  => {'other.example.org' => {
            login    => '12345',
            password => 'mytoken',
            zone     => 'example.com',
            server   => $ep,
            wantipv4 => '192.0.2.1',
        }},
        wantrecap => {},
        wantlogs  => [
            {label => 'FAILED', ctx => ['other.example.org'],
             msg => qr/does not end with zone/},
        ],
    },
);

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    diag('==============================================================================');
    local $ddclient::globals{debug}   = 1;
    local $ddclient::globals{verbose} = 1;
    my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
    local %ddclient::config = %{$tc->{cfg}};
    local %ddclient::recap;
    {
        local $ddclient::_l = $l;
        ddclient::nic_dnspod_update(undef, sort(keys(%{$tc->{cfg}})));
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
                is($got->{label}, $want->{label}, "label matches");
                is_deeply($got->{ctx}, $want->{ctx}, "context matches");
                like($got->{msg}, $want->{msg}, "message matches");
            }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
        }
        my @unexpected = @got[@want .. $#got];
        ok(@unexpected == 0, "no unexpected logs")
            or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
        my @missing = @want[@got .. $#want];
        ok(@missing == 0, "no missing logs")
            or diag(ddclient::repr(\@missing, Names => ['*missing']));
    });
    httpd()->reset();
}

done_testing();
