use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

ddclient::load_json_support('arvancloud');

httpd()->run(sub { return undef });

my $ep = httpd()->endpoint();

sub records_resp {
    my ($records) = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({ data => $records })]];
}

sub put_resp {
    my ($rec) = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({ message => 'OK', data => $rec })]];
}

sub not_found_resp {
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({ data => [] })]];
}

sub bad_json_resp {
    return [200, ['Content-Type' => 'text/plain'], ['not json at all']];
}

my @test_cases = (
    {
        desc => 'IPv4 success, Bearer token auth',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-uuid-123',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '1.2.3.4' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-uuid-123',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 300,
                cloud  => 0,
            }),
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
            is(scalar(@reqs), 2, 'two requests made');
            like($reqs[0]->uri->as_string, qr|/domains/example\.com/dns-records\?type=a&search=host|,
                 'req 0 is A record lookup');
            is($reqs[0]->header('Authorization'), 'Bearer my-arvan-token', 'Bearer token auth');
            is($reqs[1]->method, 'PUT', 'req 1 is PUT');
            like($reqs[1]->uri->as_string, qr|/domains/example\.com/dns-records/rec-uuid-123|,
                 'req 1 targets correct record');
            my $body = decode_json($reqs[1]->content);
            is($body->{value}[0]{ip}, '192.0.2.1', 'PUT body contains correct IP');
            is($body->{type}, 'a', 'PUT body has lowercase type');
            is($body->{name}, 'host', 'PUT body has correct subdomain');
        },
    },
    {
        desc => 'IPv6 success',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-uuid-456',
                name   => 'host',
                type   => 'aaaa',
                value  => [{ ip => '::1' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-uuid-456',
                name   => 'host',
                type   => 'aaaa',
                value  => [{ ip => '2001:db8::1' }],
                ttl    => 300,
                cloud  => 0,
            }),
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
            is(scalar(@reqs), 2, 'two requests made');
            like($reqs[0]->uri->as_string, qr|type=aaaa|, 'record lookup uses type aaaa');
            is($reqs[1]->method, 'PUT', 'req 1 is PUT');
        },
    },
    {
        desc => 'IPv4 + IPv6 dual-stack',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
                wantipv6 => '2001:db8::1',
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-a',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '5.6.7.8' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-a',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 300,
                cloud  => 0,
            }),
            records_resp([{
                id     => 'rec-aaaa',
                name   => 'host',
                type   => 'aaaa',
                value  => [{ ip => 'fe80::1' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-aaaa',
                name   => 'host',
                type   => 'aaaa',
                value  => [{ ip => '2001:db8::1' }],
                ttl    => 300,
                cloud  => 0,
            }),
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
            is(scalar(@reqs), 4, 'four requests: 2 lookups + 2 updates');
            like($reqs[0]->uri->as_string, qr|type=a|, 'first lookup is A record');
            like($reqs[2]->uri->as_string, qr|type=aaaa|, 'third lookup is AAAA record');
        },
    },
    {
        desc => 'IP already matches → no PUT request made',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-uuid-123',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 300,
                cloud  => 0,
            }]),
        ],
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/already set to 192\.0\.2\.1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made (GET only, no PUT)');
            is($reqs[0]->method, 'GET', 'only GET request made');
        },
    },
    {
        desc => 'Record not found → create (POST)',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            not_found_resp(),
            put_resp({
                id     => 'rec-created',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 300,
                cloud  => 0,
            }),
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
            is(scalar(@reqs), 2, 'two requests: GET + POST');
            is($reqs[0]->method, 'GET', 'first request is GET');
            is($reqs[1]->method, 'POST', 'second request is POST');
            my $body = decode_json($reqs[1]->content);
            is($body->{type}, 'a', 'POST body has type a');
            is($body->{value}[0]{ip}, '192.0.2.1', 'POST body has correct IP');
        },
    },
    {
        desc => 'Invalid JSON handling',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
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
            is(scalar(@reqs), 1, 'only one request made');
        },
    },
    {
        desc => 'HTTP 401 handling',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            [401, ['Content-Type' => 'application/json'],
             [encode_json({ message => 'Unauthorized' })]],
        ],
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/401/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only one request made');
        },
    },
    {
        desc => 'Custom TTL passed through',
        cfg => {
            'host.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
                ttl      => 600,
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-uuid-123',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '5.6.7.8' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-uuid-123',
                name   => 'host',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 600,
                cloud  => 0,
            }),
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
            is(scalar(@reqs), 2, 'two requests made');
            my $body = decode_json($reqs[1]->content);
            is($body->{ttl}, 600, 'PUT body has custom TTL');
        },
    },
    {
        desc => 'Subdomain with multiple parts (deep subdomain)',
        cfg => {
            'www.api.example.com' => {
                login    => 'my-arvan-token',
                server   => $ep,
                wantipv4 => '192.0.2.1',
            },
        },
        responses => [
            records_resp([{
                id     => 'rec-deep',
                name   => 'www.api',
                type   => 'a',
                value  => [{ ip => '9.9.9.9' }],
                ttl    => 300,
                cloud  => 0,
            }]),
            put_resp({
                id     => 'rec-deep',
                name   => 'www.api',
                type   => 'a',
                value  => [{ ip => '192.0.2.1' }],
                ttl    => 300,
                cloud  => 0,
            }),
        ],
        wantrecap => {
            'www.api.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['www.api.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            like($reqs[0]->uri->as_string, qr|search=www\.api|, 'search uses deep subdomain');
            my $body = decode_json($reqs[1]->content);
            is($body->{name}, 'www.api', 'PUT body has correct deep subdomain');
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
            ddclient::nic_arvancloud_update(undef, @hosts);
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
