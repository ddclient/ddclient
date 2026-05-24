use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('spaceship');

my $j = ['Content-Type' => 'application/json'];

sub empty_list  { encode_json({items => [], total => 0}) }
sub record_list {
    my @recs = @_;
    encode_json({items => \@recs, total => scalar(@recs)});
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            is(scalar(@reqs), 2, 'exactly 2 requests');
            is($reqs[0]->method(), 'GET',  'first request is GET');
            like($reqs[0]->uri()->path(), qr{/api/v1/dns/records/example\.com}, 'GET path correct');
            is($reqs[1]->method(), 'PUT',  'second request is PUT');
            my $body = decode_json($reqs[1]->content());
            is($body->{items}[0]{type},    'A',         'PUT type is A');
            is($body->{items}[0]{name},    'host',      'PUT name is subdomain');
            is($body->{items}[0]{address}, '192.0.2.1', 'PUT address is correct');
            is($body->{items}[0]{ttl},     300,         'PUT ttl defaults to 300');
        },
    },
    {
        desc => 'IPv4 success, existing record replaced',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [record_list({type => 'A', name => 'host', address => '192.0.2.99', ttl => 300})]],
            [204, [],  ['']],
            [204, [],  ['']],
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
            is(scalar(@reqs), 3, 'exactly 3 requests (GET + DELETE + PUT)');
            is($reqs[0]->method(), 'GET',    'first is GET');
            is($reqs[1]->method(), 'DELETE', 'second is DELETE');
            my $del = decode_json($reqs[1]->content());
            is($del->[0]{address}, '192.0.2.99', 'DELETE targets old address');
            is($reqs[2]->method(), 'PUT',    'third is PUT');
            my $put = decode_json($reqs[2]->content());
            is($put->{items}[0]{address}, '192.0.2.2', 'PUT sets new address');
        },
    },
    {
        desc => 'IPv6 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            my $put = decode_json($reqs[1]->content());
            is($put->{items}[0]{type},    'AAAA',       'PUT type is AAAA');
            is($put->{items}[0]{address}, '2001:db8::1','PUT address correct');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            is(scalar(@reqs), 4, '4 requests: GET+PUT for each IP version');
            is($reqs[0]->method(), 'GET', 'first GET');
            is($reqs[1]->method(), 'PUT', 'first PUT');
            is($reqs[2]->method(), 'GET', 'second GET');
            is($reqs[3]->method(), 'PUT', 'second PUT');
        },
    },
    {
        desc => 'custom TTL is sent',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            ttl      => 300,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            my $put = decode_json($reqs[1]->content());
            is($put->{items}[0]{ttl}, 300, 'custom TTL is 300');
        },
    },
    {
        desc => 'zone inferred from hostname when not set',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            like($reqs[0]->uri()->path(), qr{/api/v1/dns/records/example\.com},
                'inferred zone used in path');
            my $put = decode_json($reqs[1]->content());
            is($put->{items}[0]{name}, 'host', 'inferred subdomain is correct');
        },
    },
    {
        desc => 'correct auth headers sent',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'mykey',
            password => 'mysecret',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [204, [],  ['']],
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
            is($reqs[0]->header('X-Api-Key'),    'mykey',    'X-Api-Key header correct');
            is($reqs[0]->header('X-Api-Secret'), 'mysecret', 'X-Api-Secret header correct');
        },
    },
    {
        desc => 'API auth failure (401)',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'badkey',
            password => 'badsec',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [401, $j, [encode_json({detail => 'Unauthorized'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 401.*Unauthorized/},
        ],
    },
    {
        desc => 'rate limited (429)',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [429, $j, [encode_json({detail => 'Too Many Requests'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 429/},
        ],
    },
    {
        desc => 'PUT fails after successful GET',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_list()]],
            [500, $j, [encode_json({detail => 'Internal Server Error'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 500/},
        ],
    },
    {
        desc => 'DELETE fails, no PUT attempted',
        cfg => {'host.example.com' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [record_list({type => 'A', name => 'host', address => '192.0.2.99', ttl => 300})]],
            [500, $j, [encode_json({detail => 'Delete failed'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 500/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, 'only 2 requests: GET + failed DELETE, no PUT');
            is($reqs[1]->method(), 'DELETE', 'second request is DELETE');
        },
    },
    {
        desc => 'hostname does not end with zone',
        cfg => {'other.example.org' => {
            protocol => 'spaceship',
            login    => 'key1',
            password => 'sec1',
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
            ddclient::nic_spaceship_update(undef, sort(keys(%{$tc->{cfg}})));
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
