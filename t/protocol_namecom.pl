use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('namecom');

my $j = ['Content-Type' => 'application/json'];

sub empty_records  { encode_json({records => []}) }
sub record_list {
    my @recs = @_;
    encode_json({records => \@recs});
}
sub make_record {
    my (%args) = @_;
    return {
        id         => $args{id}     // 123,
        domainName => $args{zone}   // 'example.com',
        host       => $args{host}   // 'host',
        fqdn       => $args{fqdn}   // 'host.example.com.',
        type       => $args{type}   // 'A',
        answer     => $args{answer} // '192.0.2.1',
        ttl        => $args{ttl}    // 300,
    };
}
sub record_resp { encode_json(make_record(@_)) }

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record (POST create)',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(answer => '192.0.2.1')]],
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
            is(scalar(@reqs), 2, 'exactly 2 requests: GET + POST');
            is($reqs[0]->method(), 'GET',  'first request is GET');
            like($reqs[0]->uri()->path(), qr{/v4/domains/example\.com/records$}, 'GET path correct');
            is($reqs[1]->method(), 'POST', 'second request is POST (create)');
            my $body = decode_json($reqs[1]->content());
            is($body->{type},   'A',         'POST type is A');
            is($body->{host},   'host',      'POST host is subdomain');
            is($body->{answer}, '192.0.2.1', 'POST answer is correct');
            is($body->{ttl},    300,         'POST ttl defaults to 300');
        },
    },
    {
        desc => 'IPv4 success, existing record updated (PUT)',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [record_list(make_record(id => 42, answer => '192.0.2.99'))]],
            [200, $j, [record_resp(id => 42, answer => '192.0.2.2')]],
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
            is(scalar(@reqs), 2, 'exactly 2 requests: GET + PUT');
            is($reqs[0]->method(), 'GET', 'first request is GET');
            is($reqs[1]->method(), 'PUT', 'second request is PUT (update)');
            like($reqs[1]->uri()->path(), qr{/v4/domains/example\.com/records/42$}, 'PUT path includes record id');
            my $body = decode_json($reqs[1]->content());
            is($body->{answer}, '192.0.2.2', 'PUT sets new address');
        },
    },
    {
        desc => 'IPv6 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(type => 'AAAA', answer => '2001:db8::1')]],
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
            my $body = decode_json($reqs[1]->content());
            is($body->{type},   'AAAA',       'POST type is AAAA');
            is($body->{answer}, '2001:db8::1', 'POST answer is IPv6 address');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(answer => '192.0.2.1')]],
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(type => 'AAAA', answer => '2001:db8::1')]],
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
            is(scalar(@reqs), 4, '4 requests: GET+POST for each IP version');
            is($reqs[0]->method(), 'GET',  'first GET');
            is($reqs[1]->method(), 'POST', 'first POST');
            is($reqs[2]->method(), 'GET',  'second GET');
            is($reqs[3]->method(), 'POST', 'second POST');
        },
    },
    {
        desc => 'custom TTL is sent',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            ttl      => 600,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(ttl => 600)]],
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
        desc => 'apex domain (host eq zone)',
        cfg => {'example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp(host => '', fqdn => 'example.com.', answer => '192.0.2.1')]],
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
            my $body = decode_json($reqs[1]->content());
            is($body->{host}, '', 'apex domain sends empty host string');
        },
    },
    {
        desc => 'correct Basic auth credentials sent',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'testuser',
            password => 'testtoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_records()]],
            [201, $j, [record_resp()]],
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
            my $auth = $reqs[0]->header('Authorization') // '';
            like($auth, qr/^Basic /, 'Authorization header uses Basic scheme');
            my ($encoded) = ($auth =~ /^Basic (.+)$/);
            my $decoded = MIME::Base64::decode_base64($encoded);
            is($decoded, 'testuser:testtoken', 'Basic auth credentials are correct');
        },
    },
    {
        desc => 'API auth failure (401)',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'baduser',
            password => 'badtoken',
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
        desc => 'zone not found (404)',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, [encode_json({message => 'Domain not found'})]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/API error 404.*Domain not found/},
        ],
    },
    {
        desc => 'POST fails after successful GET',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [empty_records()]],
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
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
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
        desc => 'no IP addresses to update (no-op)',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
        }},
        responses => [],
        wantrecap => {},
        wantlogs  => [],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 0, 'no HTTP requests when no IPs to update');
        },
    },
    {
        desc => 'existing record matched by fqdn and type only',
        cfg => {'host.example.com' => {
            protocol => 'namecom',
            login    => 'myuser',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.5',
        }},
        responses => [
            [200, $j, [record_list(
                # A record for host.example.com. — should be matched
                make_record(id => 7, type => 'A',    fqdn => 'host.example.com.', answer => '192.0.2.99'),
                # AAAA record for same host — should NOT be matched for A update
                make_record(id => 8, type => 'AAAA', fqdn => 'host.example.com.', answer => '2001:db8::1'),
                # A record for different host — should NOT be matched
                make_record(id => 9, type => 'A',    fqdn => 'other.example.com.', answer => '10.0.0.1'),
            )]],
            [200, $j, [record_resp(id => 7, answer => '192.0.2.5')]],
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
            is(scalar(@reqs), 2, '2 requests: GET + PUT');
            like($reqs[1]->uri()->path(), qr{/records/7$}, 'PUT targets correct record id');
        },
    },
);

use MIME::Base64;

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
            ddclient::nic_namecom_update(undef, sort(keys(%{$tc->{cfg}})));
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
