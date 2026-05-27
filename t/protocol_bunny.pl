use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

ddclient::load_json_support('bunny');

httpd()->run();

# Helper: build a standard zone-list response
sub zone_list_response {
    my ($zone, $zone_id) = @_;
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        Items       => [{ Id => $zone_id, Domain => $zone }],
        TotalItems  => 1,
        CurrentPage => 1,
        HasMoreItems => 0,
    })]];
}

# Helper: build a zone-detail response with optional records
sub zone_detail_response {
    my ($zone_id, @records) = @_;
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        Id      => $zone_id,
        Domain  => 'example.com',
        Records => \@records,
    })]];
}

my $ep  = httpd()->endpoint();
my $now = $ddclient::now;

my @test_cases = (

    {
        desc => 'IPv4 success, existing record updated',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_list_response('example.com', 42),
            zone_detail_response(42, {Id => 10, Type => 0, Name => 'myhost', Value => '198.51.100.1', Ttl => 300}),
            [200, ['Content-Type' => 'application/json'], [encode_json({})]],
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
            {method => 'GET', path_re => qr{/dnszone/42$}},
            {method => 'POST', path_re => qr{/dnszone/42/records/10$}},
        ],
    },

    {
        desc => 'IPv6 success, existing record updated',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            zone_list_response('example.com', 42),
            zone_detail_response(42, {Id => 20, Type => 1, Name => 'myhost', Value => '2001:db8::2', Ttl => 300}),
            [200, ['Content-Type' => 'application/json'], [encode_json({})]],
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
            {method => 'GET', path_re => qr{/dnszone/42$}},
            {method => 'POST', path_re => qr{/dnszone/42/records/20$}},
        ],
    },

    {
        desc => 'dual-stack success, both records updated',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            zone_list_response('example.com', 42),
            zone_detail_response(42,
                {Id => 10, Type => 0, Name => 'myhost', Value => '198.51.100.1', Ttl => 300},
                {Id => 20, Type => 1, Name => 'myhost', Value => '2001:db8::2', Ttl => 300},
            ),
            [200, ['Content-Type' => 'application/json'], [encode_json({})]],
            [200, ['Content-Type' => 'application/json'], [encode_json({})]],
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
            {method => 'GET', path_re => qr{/dnszone/42$}},
            {method => 'POST', path_re => qr{/dnszone/42/records/10$}},
            {method => 'POST', path_re => qr{/dnszone/42/records/20$}},
        ],
    },

    {
        desc => 'zone not found',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            [200, ['Content-Type' => 'application/json'], [encode_json({
                Items       => [],
                TotalItems  => 0,
                CurrentPage => 1,
                HasMoreItems => 0,
            })]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/zone 'example\.com' not found/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
        ],
    },

    {
        desc => 'record not found, created via PUT',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_list_response('example.com', 42),
            zone_detail_response(42),
            [200, ['Content-Type' => 'application/json'], [encode_json({})]],
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
            {method => 'GET', path_re => qr{/dnszone/42$}},
            {method => 'PUT', path_re => qr{/dnszone/42/records$}},
        ],
    },

    {
        desc => 'HTTP error on zone list',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            [401, ['Content-Type' => 'application/json'], [encode_json({Message => 'Unauthorized'})]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/401/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
        ],
    },

    {
        desc => 'no-op when IP already matches',
        cfg => {
            'myhost.example.com' => {
                server   => $ep,
                password => 'test-api-key',
                zone     => 'example.com',
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_list_response('example.com', 42),
            zone_detail_response(42, {Id => 10, Type => 0, Name => 'myhost', Value => '192.0.2.1', Ttl => 300}),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/skipped: IPv4 address was already set to 192\.0\.2\.1/},
        ],
        wantreqs => [
            {method => 'GET', path_re => qr{/dnszone\b}},
            {method => 'GET', path_re => qr{/dnszone/42$}},
        ],
    },

);

for my $tc (@test_cases) {
    diag('=' x 78);
    diag("Starting test: $tc->{desc}");
    diag('=' x 78);

    httpd()->reset(@{$tc->{responses}});

    local %ddclient::config = ();
    my @hosts = sort(keys(%{$tc->{cfg}}));
    for my $h (@hosts) {
        $ddclient::config{$h} = {%{$tc->{cfg}{$h}}};
    }
    local %ddclient::recap;
    my $l = ddclient::t::Logger->new(
        $ddclient::_l,
        qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/,
    );
    {
        local $ddclient::_l = $l;
        ddclient::nic_bunny_update(undef, @hosts);
    }
    my @got_reqs = httpd()->reset();

    is_deeply(\%ddclient::recap, $tc->{wantrecap}, "$tc->{desc}: recap")
        or diag(ddclient::repr(
            Values => [\%ddclient::recap, $tc->{wantrecap}],
            Names  => ['*got', '*want'],
        ));

    subtest("$tc->{desc}: requests" => sub {
        my @wantreqs = @{$tc->{wantreqs} // []};
        is(scalar(@got_reqs), scalar(@wantreqs), "request count matches");
        for my $i (0 .. $#wantreqs) {
            last if $i >= @got_reqs;
            my $req  = $got_reqs[$i];
            my $want = $wantreqs[$i];
            subtest("request $i" => sub {
                is($req->method(), $want->{method}, "method is $want->{method}");
                like($req->uri()->path(), $want->{path_re}, "path matches");
                is($req->header('AccessKey'), 'test-api-key', 'AccessKey header present');
            });
        }
    });

    $tc->{wantlogs} //= [];
    subtest("$tc->{desc}: logs" => sub {
        my @got  = @{$l->{logs}};
        my @want = @{$tc->{wantlogs}};
        for my $i (0 .. $#want) {
            last if $i >= @got;
            my $got  = $got[$i];
            my $want = $want[$i];
            subtest("log $i" => sub {
                is($got->{label},      $want->{label},   "label matches");
                is_deeply($got->{ctx}, $want->{ctx},     "context matches");
                like($got->{msg},      $want->{msg},     "message matches");
            }) or diag(ddclient::repr(
                Values => [$got, $want],
                Names  => ['*got', '*want'],
            ));
        }
        my @unexpected = @got[@want .. $#got];
        ok(@unexpected == 0, "no unexpected logs")
            or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
        my @missing = @want[@got .. $#want];
        ok(@missing == 0, "no missing logs")
            or diag(ddclient::repr(\@missing, Names => ['*missing']));
    });
}

done_testing();
