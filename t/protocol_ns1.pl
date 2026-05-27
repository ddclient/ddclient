use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('ns1');

my $j = ['Content-Type' => 'application/json'];

sub record_resp {
    my ($ip, $type) = @_;
    encode_json({
        zone    => 'example.com',
        domain  => 'host.example.com',
        type    => $type // 'A',
        answers => [{ answer => [$ip] }],
        ttl     => 3600,
    });
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record (PUT)',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'record not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
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
            is(scalar(@reqs), 2, 'exactly 2 requests: GET + PUT');
            is($reqs[0]->method(), 'GET', 'first request is GET');
            like($reqs[0]->uri()->path(), qr{/zones/example\.com/host\.example\.com/A}, 'GET path correct');
            is($reqs[1]->method(), 'PUT', 'second request is PUT (new record)');
            my $body = decode_json($reqs[1]->content());
            is($body->{answers}[0]{answer}[0], '192.0.2.1', 'PUT answer correct');
            is($body->{ttl}, 300, 'PUT ttl defaults to 300');
        },
    },
    {
        desc => 'IPv4 success, existing record updated (POST)',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [record_resp('192.0.2.99')]],
            [200, $j, [record_resp('192.0.2.2')]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.2',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, 'exactly 2 requests: GET + POST');
            is($reqs[0]->method(), 'GET',  'first request is GET');
            is($reqs[1]->method(), 'POST', 'second request is POST (update existing)');
            my $body = decode_json($reqs[1]->content());
            is($body->{answers}[0]{answer}[0], '192.0.2.2', 'POST answer correct');
        },
    },
    {
        desc => 'IPv6 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'record not found'})]],
            [200, $j, [record_resp('2001:db8::1', 'AAAA')]],
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, 'exactly 2 requests');
            like($reqs[0]->uri()->path(), qr{/AAAA$}, 'GET path ends with AAAA');
            is($reqs[1]->method(), 'PUT', 'PUT for new AAAA record');
            my $body = decode_json($reqs[1]->content());
            is($body->{answers}[0]{answer}[0], '2001:db8::1', 'PUT answer correct');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('2001:db8::1', 'AAAA')]],
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
            is(scalar(@reqs), 4, '4 requests: GET+PUT for each version');
            is($reqs[0]->method(), 'GET', 'first GET');
            is($reqs[1]->method(), 'PUT', 'first PUT');
            is($reqs[2]->method(), 'GET', 'second GET');
            is($reqs[3]->method(), 'PUT', 'second PUT');
        },
    },
    {
        desc => 'custom TTL is sent',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            ttl      => 600,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
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
            my $body = decode_json($reqs[1]->content());
            is($body->{ttl}, 600, 'custom TTL 600 is sent');
        },
    },
    {
        desc => 'zone inferred from hostname when not set',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
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
            like($reqs[0]->uri()->path(), qr{/zones/example\.com/}, 'inferred zone used in path');
        },
    },
    {
        desc => 'correct auth header sent',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'supersecretkey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
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
            is($reqs[0]->header('X-NSONE-Key'), 'supersecretkey', 'X-NSONE-Key header correct');
        },
    },
    {
        desc => 'API auth failure (401)',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'badkey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [401, $j, [encode_json({message => 'Unauthorized'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 401.*Unauthorized/},
        ],
    },
    {
        desc => 'PUT fails after 404 GET',
        cfg => {'host.example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [500, $j, [encode_json({message => 'Internal Server Error'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 500/},
        ],
    },
    {
        desc => 'hostname does not end with zone',
        cfg => {'other.example.org' => {
            protocol => 'ns1',
            login    => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['other.example.org'], msg => qr/does not end with zone/},
        ],
    },
    {
        desc => 'bare hostname without dot fails with useful error',
        cfg => {'localhostname' => {
            protocol => 'ns1',
            login    => 'myapikey',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['localhostname'], msg => qr/no dot in hostname.*use zone=/},
        ],
    },
    {
        desc => 'apex domain inferred as zone when hostname has exactly one dot',
        cfg => {'example.com' => {
            protocol => 'ns1',
            login    => 'myapikey',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'not found'})]],
            [200, $j, [record_resp('192.0.2.1')]],
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
            like($reqs[0]->uri()->path(), qr{/zones/example\.com/example\.com/A}, 'apex zone used in path');
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
            ddclient::nic_ns1_update(undef, sort(keys(%{$tc->{cfg}})));
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
