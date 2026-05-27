use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('netlify');

my $j = ['Content-Type' => 'application/json'];

# Helper responses
sub zones_ok { encode_json([{id => 'zone123', name => 'example.com'}]) }
sub records_empty { encode_json([]) }
sub records_with_a {
    encode_json([{id => 'rec456', type => 'A', hostname => 'host.example.com',
                  value => '192.0.2.99', ttl => 1}])
}
sub records_with_aaaa {
    encode_json([{id => 'rec789', type => 'AAAA', hostname => 'host.example.com',
                  value => '2001:db8::99', ttl => 1}])
}
sub records_with_both {
    encode_json([
        {id => 'rec456', type => 'A',    hostname => 'host.example.com',
         value => '192.0.2.99', ttl => 1},
        {id => 'rec789', type => 'AAAA', hostname => 'host.example.com',
         value => '2001:db8::99', ttl => 1},
    ])
}
sub create_ok { encode_json({id => 'recnew', type => 'A', hostname => 'host.example.com',
                              value => '192.0.2.1', ttl => 1}) }
sub create_aaaa_ok { encode_json({id => 'recnew', type => 'AAAA', hostname => 'host.example.com',
                                  value => '2001:db8::1', ttl => 1}) }

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record (create)',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_ok()]],
            [200, $j, [records_empty()]],
            [201, $j, [create_ok()]],
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
            is($reqs[0]->method(), 'GET',  'first is GET');
            like($reqs[0]->uri()->path(), qr{/dns_zones$}, 'GET zones path correct');
            is($reqs[1]->method(), 'GET',  'second is GET records');
            like($reqs[1]->uri()->path(), qr{/dns_zones/zone123/dns_records}, 'GET records path correct');
            is($reqs[2]->method(), 'POST', 'third is POST create');
            like($reqs[2]->uri()->path(), qr{/dns_zones/zone123/dns_records}, 'POST to dns_records for create');
            my $body = decode_json($reqs[2]->content());
            is($body->{type},     'A',           'create type is A');
            is($body->{hostname}, 'host.example.com', 'create hostname is fqdn');
            is($body->{value},    '192.0.2.1',   'create value correct');
        },
    },
    {
        desc => 'IPv4 success, existing record (delete + create)',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [zones_ok()]],
            [200, $j, [records_with_a()]],
            [204, $j, ['']],
            [201, $j, [encode_json({id => 'recnew', type => 'A',
                                    hostname => 'host.example.com',
                                    value => '192.0.2.2', ttl => 1})]],
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
            is(scalar(@reqs), 4, '4 requests: GET zones + GET records + DELETE + POST');
            is($reqs[2]->method(), 'DELETE', 'third is DELETE');
            like($reqs[2]->uri()->path(), qr{/dns_zones/zone123/dns_records/rec456},
                'DELETE targets existing record ID');
            is($reqs[3]->method(), 'POST', 'fourth is POST create');
        },
    },
    {
        desc => 'IPv6 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [zones_ok()]],
            [200, $j, [records_empty()]],
            [201, $j, [create_aaaa_ok()]],
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
            my $body = decode_json($reqs[2]->content());
            is($body->{type},  'AAAA',        'create type is AAAA for IPv6');
            is($body->{value}, '2001:db8::1', 'create value correct');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            # zone lookup (shared)
            [200, $j, [zones_ok()]],
            # IPv4: records + create
            [200, $j, [records_empty()]],
            [201, $j, [create_ok()]],
            # IPv6: records + create
            [200, $j, [records_empty()]],
            [201, $j, [create_aaaa_ok()]],
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
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'notfound.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_ok()]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/zone.*notfound\.com.*not found/},
        ],
    },
    {
        desc => 'HTTP error on zone lookup',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [401, $j, [encode_json({message => 'Unauthorized'})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/401/},
        ],
    },
    {
        desc => 'HTTP error on record listing',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_ok()]],
            [500, $j, [encode_json({message => 'Internal Server Error'})]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/500/},
        ],
    },
    {
        desc => 'correct Authorization header sent',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'supersecrettoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [zones_ok()]],
            [200, $j, [records_empty()]],
            [201, $j, [create_ok()]],
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
                'Authorization header is correct');
        },
    },
    {
        desc => 'no-op: no IPs to update',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
        }},
        responses => [
            [200, $j, [zones_ok()]],
        ],
        wantrecap => {},
        wantlogs  => [],
    },
    {
        desc => 'invalid JSON from dns_zones',
        cfg => {'host.example.com' => {
            protocol => 'netlify',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, ['Content-Type' => 'application/json'], ['not-json']],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'failed',
        }},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/invalid JSON/},
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
            ddclient::nic_netlify_update(undef, sort(keys(%{$tc->{cfg}})));
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
