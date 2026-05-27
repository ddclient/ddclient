use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('namesilo');

my $j = ['Content-Type' => 'application/json'];

sub list_resp {
    my ($records) = @_;
    $records //= [];
    return [200, $j, [encode_json({
        reply => {
            code            => 300,
            detail          => 'success',
            resource_record => $records,
        },
    })]];
}

sub list_resp_single_record {
    my ($record) = @_;
    return [200, $j, [encode_json({
        reply => {
            code            => 300,
            detail          => 'success',
            resource_record => $record,
        },
    })]];
}

sub ok_resp {
    return [200, $j, [encode_json({
        reply => {
            code   => 300,
            detail => 'success',
        },
    })]];
}

sub error_resp {
    my ($code, $detail) = @_;
    return [200, $j, [encode_json({
        reply => {
            code   => $code,
            detail => $detail,
        },
    })]];
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, add new record',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            list_resp([]),
            ok_resp(),
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
            is(scalar(@reqs), 2, 'exactly 2 requests: list + add');
            like($reqs[0]->uri()->path(), qr{/api/dnsListRecords}, 'first request is dnsListRecords');
            like($reqs[0]->uri()->query(), qr/domain=example\.com/, 'list query has domain');
            like($reqs[0]->uri()->query(), qr/key=myapikey/, 'list query has API key');
            like($reqs[1]->uri()->path(), qr{/api/dnsAddRecord}, 'second request is dnsAddRecord');
            like($reqs[1]->uri()->query(), qr/rrtype=A/, 'add query has rrtype=A');
            like($reqs[1]->uri()->query(), qr/rrvalue=192\.0\.2\.1/, 'add query has correct IP');
            like($reqs[1]->uri()->query(), qr/rrhost=host/, 'add query has subdomain');
        },
    },
    {
        desc => 'IPv4 success, update existing record',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            list_resp([{
                record_id => 'rec123',
                type      => 'A',
                host      => 'host.example.com',
                value     => '192.0.2.1',
                ttl       => 3600,
            }]),
            ok_resp(),
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
            is(scalar(@reqs), 2, 'exactly 2 requests: list + update');
            like($reqs[0]->uri()->path(), qr{/api/dnsListRecords}, 'first request is dnsListRecords');
            like($reqs[1]->uri()->path(), qr{/api/dnsUpdateRecord}, 'second request is dnsUpdateRecord');
            like($reqs[1]->uri()->query(), qr/rrid=rec123/, 'update query has record ID');
            like($reqs[1]->uri()->query(), qr/rrvalue=192\.0\.2\.2/, 'update query has new IP');
            like($reqs[1]->uri()->query(), qr/rrhost=host/, 'update query has subdomain');
        },
    },
    {
        desc => 'IPv6 success, add new record',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            list_resp([]),
            ok_resp(),
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
            is(scalar(@reqs), 2, 'exactly 2 requests: list + add');
            like($reqs[1]->uri()->path(), qr{/api/dnsAddRecord}, 'second request is dnsAddRecord');
            like($reqs[1]->uri()->query(), qr/rrtype=AAAA/, 'add query has rrtype=AAAA');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            list_resp([]),
            ok_resp(),
            list_resp([]),
            ok_resp(),
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
            is(scalar(@reqs), 4, '4 requests: list+add for each version');
        },
    },
    {
        desc => 'API error on list records',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'badkey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            error_resp(110, 'Invalid API Key'),
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Invalid API Key/},
        ],
    },
    {
        desc => 'API error on update record',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            list_resp([{
                record_id => 'rec456',
                type      => 'A',
                host      => 'host.example.com',
                value     => '192.0.2.99',
                ttl       => 3600,
            }]),
            error_resp(200, 'Record update failed'),
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Record update failed/},
        ],
    },
    {
        desc => 'hostname does not end with zone',
        cfg => {'other.example.org' => {
            protocol => 'namesilo',
            password => 'myapikey',
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
        desc => 'custom TTL is sent',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            ttl      => 7200,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            list_resp([]),
            ok_resp(),
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
            like($reqs[1]->uri()->query(), qr/rrttl=7200/, 'custom TTL 7200 sent in add request');
        },
    },
    {
        desc => 'apex domain uses @ as subdomain',
        cfg => {'example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            list_resp([]),
            ok_resp(),
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
            like($reqs[1]->uri()->query(), qr/rrhost=(?:@|%40)/, 'apex domain sends @ as subdomain');
        },
    },
    {
        desc => 'single existing record returned as hash (not array)',
        cfg => {'host.example.com' => {
            protocol => 'namesilo',
            password => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.5',
        }},
        responses => [
            list_resp_single_record({
                record_id => 'recabc',
                type      => 'A',
                host      => 'host.example.com',
                value     => '192.0.2.4',
                ttl       => 3600,
            }),
            ok_resp(),
        ],
        wantrecap => {'host.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.5',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            like($reqs[1]->uri()->path(), qr{/api/dnsUpdateRecord}, 'update used when single hash record matches');
            like($reqs[1]->uri()->query(), qr/rrid=recabc/, 'correct record ID used');
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
            ddclient::nic_namesilo_update(undef, sort(keys(%{$tc->{cfg}})));
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
