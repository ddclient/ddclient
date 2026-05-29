use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('hosttech');

my $j = ['Content-Type' => 'application/json'];

# Helper to build a zones-list response containing one zone
sub zones_resp {
    my ($id, $name) = @_;
    return encode_json({data => [{id => $id, name => $name, ttl => 3600, dnssec => 0}]});
}

# Helper to build a records-list response with zero or one A/AAAA record
sub records_resp_empty { encode_json({data => []}) }

sub records_resp_a {
    my ($id, $name, $ip) = @_;
    return encode_json({data => [{id => $id, type => 'A', name => $name, ipv4 => $ip, ttl => 600, comment => ''}]});
}

sub records_resp_aaaa {
    my ($id, $name, $ip) = @_;
    return encode_json({data => [{id => $id, type => 'AAAA', name => $name, ipv6 => $ip, ttl => 600, comment => ''}]});
}

# Helper to build a single-record response (used for POST/PUT result)
sub record_created_a {
    my ($id, $name, $ip) = @_;
    return encode_json({data => {id => $id, type => 'A', name => $name, ipv4 => $ip, ttl => 600, comment => ''}});
}

sub record_created_aaaa {
    my ($id, $name, $ip) = @_;
    return encode_json({data => {id => $id, type => 'AAAA', name => $name, ipv6 => $ip, ttl => 600, comment => ''}});
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record (create)',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_a(101, 'host', '192.0.2.1')]],
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
            is(scalar(@reqs), 3, '3 requests: GET zones + GET records + POST create');
            is($reqs[0]->method(), 'GET', 'first request is GET (zones)');
            like($reqs[0]->uri()->path(), qr{/user/v1/zones}, 'zones endpoint path correct');
            like($reqs[0]->uri()->query(), qr{query=example\.com}, 'zones query param correct');
            is($reqs[1]->method(), 'GET', 'second request is GET (records)');
            like($reqs[1]->uri()->path(), qr{/user/v1/zones/42/records}, 'records path uses zone id');
            like($reqs[1]->uri()->query(), qr{type=A}, 'records query filters by type A');
            is($reqs[2]->method(), 'POST', 'third request is POST (create)');
            like($reqs[2]->uri()->path(), qr{/user/v1/zones/42/records$}, 'POST to records endpoint');
            my $body = decode_json($reqs[2]->content());
            is($body->{type}, 'A',          'create: type is A');
            is($body->{name}, 'host',        'create: name is subdomain');
            is($body->{ipv4}, '192.0.2.1',   'create: ipv4 value correct');
        },
    },
    {
        desc => 'IPv4 success, existing record (update)',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_a(101, 'host', '192.0.2.1')]],
            [200, $j, [record_created_a(101, 'host', '192.0.2.2')]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.2',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4.*192\.0\.2\.2/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 3, '3 requests: GET zones + GET records + PUT update');
            is($reqs[2]->method(), 'PUT', 'third request is PUT (update)');
            like($reqs[2]->uri()->path(), qr{/user/v1/zones/42/records/101$}, 'PUT to record by id');
            my $body = decode_json($reqs[2]->content());
            is($body->{ipv4}, '192.0.2.2', 'update: ipv4 value correct');
        },
    },
    {
        desc => 'IPv6 success, no existing record (create)',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_aaaa(102, 'host', '2001:db8::1')]],
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
            like($reqs[1]->uri()->query(), qr{type=AAAA}, 'records query filters by type AAAA');
            is($reqs[2]->method(), 'POST', 'third request is POST (create AAAA)');
            my $body = decode_json($reqs[2]->content());
            is($body->{type}, 'AAAA',         'create: type is AAAA');
            is($body->{ipv6}, '2001:db8::1',  'create: ipv6 value correct');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            # zones lookup (once for the domain)
            [200, $j, [zones_resp(42, 'example.com')]],
            # IPv4: records + create
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_a(101, 'host', '192.0.2.1')]],
            # IPv6: records + create
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_aaaa(102, 'host', '2001:db8::1')]],
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
    },
    {
        desc => 'zone not found',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [encode_json({data => []})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/zone.*example\.com.*not found/i},
        ],
    },
    {
        desc => 'HTTP error on zone listing',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [500, $j, [encode_json({message => 'internal server error'})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/500/},
        ],
    },
    {
        desc => 'HTTP error on record update',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_empty()]],
            [422, $j, [encode_json({message => 'validation error'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/422/},
        ],
    },
    {
        desc => 'correct Authorization header sent',
        cfg => {'host.example.com' => {
            protocol => 'hosttech',
            password => 'supersecrettoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_a(101, 'host', '192.0.2.1')]],
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
            like($reqs[0]->header('Authorization'), qr/^Bearer supersecrettoken$/,
                'Authorization header is Bearer token');
        },
    },
    {
        desc => 'apex domain — hostname equals zone',
        cfg => {'example.com' => {
            protocol => 'hosttech',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_resp(42, 'example.com')]],
            [200, $j, [records_resp_empty()]],
            [201, $j, [record_created_a(101, '', '192.0.2.1')]],
        ],
        wantrecap => {'example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            my $body = decode_json($reqs[2]->content());
            is($body->{name}, '', 'apex domain: name is empty string');
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
            ddclient::nic_hosttech_update(undef, sort(keys(%{$tc->{cfg}})));
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
