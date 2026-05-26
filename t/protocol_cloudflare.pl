use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

ddclient::load_json_support('cloudflare');

httpd()->run(sub { return undef });

my $ep = httpd()->endpoint();

sub zone_resp {
    my ($zone_name, $zone_id) = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({success => \1, result => [{id => $zone_id, name => $zone_name}]})]];
}

sub rec_resp {
    my ($host, $rec_id) = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({success => \1, result => [{id => $rec_id, name => $host}]})]];
}

sub patch_resp {
    my ($rec_id) = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({success => \1, result => {id => $rec_id}})]];
}

sub empty_result_resp {
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({success => \1, result => []})]];
}

sub bad_json_resp {
    return [200, ['Content-Type' => 'text/plain'], ['not json at all']];
}

my @test_cases = (
    {
        desc => 'IPv4 success, Bearer token auth',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'rec222'),
            patch_resp('rec222'),
        ],
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 3, 'three requests made');
            like($reqs[0]->uri->as_string, qr|/zones/\?name=example\.com|, 'req 0 is zone lookup');
            is($reqs[0]->header('Authorization'), 'Bearer mytoken', 'Bearer token auth on zone lookup');
            like($reqs[1]->uri->as_string, qr|/zones/zone111/dns_records\?type=A&name=host\.example\.com|, 'req 1 is A record lookup');
            is($reqs[2]->method, 'PATCH', 'req 2 is PATCH');
            like($reqs[2]->uri->as_string, qr|/zones/zone111/dns_records/rec222|, 'req 2 targets correct record');
            my $body = decode_json($reqs[2]->content);
            is($body->{content}, '192.0.2.1', 'PATCH body contains correct IP');
        },
    },
    {
        desc => 'IPv4 success, email+key auth',
        cfg => {
            'host.example.com' => {
                login    => 'user@example.com',
                password => 'globalapikey',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'rec222'),
            patch_resp('rec222'),
        ],
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is($reqs[0]->header('X-Auth-Email'), 'user@example.com', 'X-Auth-Email set');
            is($reqs[0]->header('X-Auth-Key'), 'globalapikey', 'X-Auth-Key set');
            ok(!defined($reqs[0]->header('Authorization')), 'no Authorization header');
        },
    },
    {
        desc => 'IPv6 success',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'rec333'),
            patch_resp('rec333'),
        ],
        wantrecap => {
            'host.example.com' => {
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 3, 'three requests made');
            like($reqs[1]->uri->as_string, qr|type=AAAA|, 'record lookup uses type AAAA');
        },
    },
    {
        desc => 'IPv4 and IPv6 success',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'recA'),
            patch_resp('recA'),
            rec_resp('host.example.com', 'recAAAA'),
            patch_resp('recAAAA'),
        ],
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 5, 'five requests: 1 zone + 2*(record+patch)');
            like($reqs[1]->uri->as_string, qr|type=A&|, 'second request is A record lookup');
            like($reqs[3]->uri->as_string, qr|type=AAAA&|, 'fourth request is AAAA record lookup');
        },
    },
    {
        desc => 'zone not found',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            empty_result_resp(),
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/no zone ID found for zone example\.com/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made (zone lookup)');
        },
    },
    {
        desc => 'DNS record not found',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            empty_result_resp(),
        ],
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/no 'A' record at Cloudflare/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, 'two requests: zone lookup + record lookup');
        },
    },
    {
        desc => 'invalid JSON from zone lookup',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            bad_json_resp(),
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/invalid json or result/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made');
        },
    },
    # The following two cases cover JSON decoding failures at the record lookup and
    # PATCH phases.  They exposed a bug: the regex that extracts the JSON object from
    # the HTTP response (qr/{...}/mp) does not reset ${^MATCH} on a failed match, so
    # a response containing no braces would leave ${^MATCH} holding the value from the
    # previous (zone lookup) match.  The stale JSON was silently decoded and the wrong
    # error path was taken.  The fix checks the match return value before use.
    {
        desc => 'invalid JSON from DNS record lookup',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            bad_json_resp(),
        ],
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/invalid json or result/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, 'two requests: zone lookup + record lookup');
        },
    },
    {
        desc => 'invalid JSON from PATCH',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'rec222'),
            bad_json_resp(),
        ],
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/invalid json or result/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 3, 'three requests: zone lookup + record lookup + PATCH');
            is($reqs[2]->method, 'PATCH', 'third request is PATCH');
        },
    },
    # Scoped API tokens (login='token') can fail at the HTTP level in two ways that
    # global API keys do not produce:
    #
    #   HTTP 401 -- the token is invalid, expired, or revoked.  Cloudflare rejects it
    #               before evaluating any resource permissions.  Because the zone
    #               lookup is the first request, the update never proceeds.
    #
    #   HTTP 403 -- the token is valid and authenticated but lacks the permission
    #               needed for the specific operation.  A common real-world example is
    #               a token that has Zone:Read and DNS:Read but not DNS:Edit: zone
    #               lookup and record lookup succeed (200 OK), but the PATCH to update
    #               the record is denied (403 Forbidden).  The status-ipv4 recap entry
    #               is already written as 'failed' before the PATCH request is made,
    #               so it remains 'failed' after the 403.
    #
    # header_ok() handles both codes and logs a FAILED message containing the status
    # code, so these tests match on the numeric code rather than the reason phrase.
    {
        desc => 'HTTP 401 on zone lookup (invalid or expired token)',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'badtoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            [401, ['Content-Type' => 'application/json'],
             [encode_json({success => \0, errors => [{code => 9109, message => 'Invalid access token'}]})]],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/401/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made (zone lookup)');
        },
    },
    {
        desc => 'HTTP 403 on PATCH (token lacks DNS edit permission)',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'readonlytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            zone_resp('example.com', 'zone111'),
            rec_resp('host.example.com', 'rec222'),
            [403, ['Content-Type' => 'application/json'],
             [encode_json({success => \0, errors => [{code => 10000, message => 'Authentication error'}]})]],
        ],
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/403/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 3, 'three requests: zone lookup + record lookup + PATCH');
            is($reqs[2]->method, 'PATCH', 'third request is PATCH');
        },
    },
    # A scoped token that lacks Zone:Zone:Read permission causes Cloudflare to return
    # HTTP 200 with a JSON body of {"success":false,"result":null,...} rather than an
    # HTTP error code.  The implementation checks $response->{result} for truthiness;
    # since null deserialises to undef, the 'unless' branch fires and logs
    # "invalid json or result".  The error message is currently generic -- it does not
    # surface the Cloudflare error code or message from the body -- but the FAILED path
    # is exercised correctly and the update is aborted.
    {
        desc => 'success:false on zone lookup (API-level permission error)',
        cfg => {
            'host.example.com' => {
                login    => 'token',
                password => 'mytoken',
                zone     => 'example.com',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            [200, ['Content-Type' => 'application/json'],
             ['{"success":false,"errors":[{"code":7003,"message":"Could not route to /zones"}],"result":null}']],
        ],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/invalid json or result/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made');
        },
    },
);

for my $tc (@test_cases) {
    subtest($tc->{desc} => sub {
        my @hosts = sort(keys(%{$tc->{cfg}}));
        local %ddclient::config = %{$tc->{cfg}};
        local %ddclient::recap;
        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        httpd()->reset(@{$tc->{responses}});
        {
            local $ddclient::_l = $l;
            ddclient::nic_cloudflare_update(undef, @hosts);
        }
        my @reqs = httpd()->reset();
        is_deeply(\%ddclient::recap, $tc->{wantrecap}, 'recap matches')
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names  => ['*got', '*want']));
        subtest('logs' => sub {
            my @got  = @{$l->{logs}};
            my @want = @{$tc->{wantlogs}};
            for my $i (0 .. $#want) {
                last if $i >= @got;
                subtest("log $i" => sub {
                    is($got[$i]{label}, $want[$i]{label}, 'label');
                    is_deeply($got[$i]{ctx}, $want[$i]{ctx}, 'context');
                    like($got[$i]{msg}, $want[$i]{msg}, 'message');
                }) or diag(ddclient::repr(Values => [$got[$i], $want[$i]], Names => ['*got', '*want']));
            }
            my @unexpected = @got[@want .. $#got];
            ok(@unexpected == 0, 'no unexpected logs')
                or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
            my @missing = @want[@got .. $#want];
            ok(@missing == 0, 'no missing logs')
                or diag(ddclient::repr(\@missing, Names => ['*missing']));
        });
        $tc->{check_reqs}->(@reqs) if $tc->{check_reqs};
    });
}

done_testing();
