use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('hetzner');

my $j = ['Content-Type' => 'application/json'];

sub action_running { encode_json({action => {id => 1, status => 'running'}}) }
sub action_success { encode_json({action => {id => 1, status => 'success'}}) }
sub action_error   { encode_json({action => {id => 1, status => 'error',
                                             error => {message => 'something went wrong'}}}) }
sub rrset_found    { encode_json({rrset => {id => 'abc123', name => $_[0], type => $_[1]}}) }

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, no existing record (create)',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
            is(scalar(@reqs), 3, '3 requests: GET + POST create + GET action');
            is($reqs[0]->method(), 'GET',  'first is GET');
            like($reqs[0]->uri()->path(), qr{/zones/example\.com/rrsets/host/A}, 'GET path correct');
            is($reqs[1]->method(), 'POST', 'second is POST create');
            like($reqs[1]->uri()->path(), qr{/zones/example\.com/rrsets$}, 'POST to rrsets for create');
            my $body = decode_json($reqs[1]->content());
            is($body->{name},              'host',      'create name is subdomain');
            is($body->{type},              'A',         'create type is A');
            is($body->{records}[0]{value}, '192.0.2.1', 'create value correct');
        },
    },
    {
        desc => 'IPv4 success, existing record (update)',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.2',
        }},
        responses => [
            [200, $j, [rrset_found('host', 'A')]],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
            is(scalar(@reqs), 3, '3 requests: GET + POST update + GET action');
            is($reqs[1]->method(), 'POST', 'second is POST');
            like($reqs[1]->uri()->path(), qr{/rrsets/host/A/actions/set_records}, 'POST to set_records for update');
        },
    },
    {
        desc => 'apex domain (@) — hostname equals zone',
        cfg => {'example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
            like($reqs[0]->uri()->path(), qr{/zones/example\.com/rrsets/@/A},
                'GET uses @ for apex, not example.com');
            my $body = decode_json($reqs[1]->content());
            is($body->{name}, '@', 'create name is @ for apex');
        },
    },
    {
        desc => 'IPv6 success, no existing record',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
            like($reqs[0]->uri()->path(), qr{/rrsets/host/AAAA}, 'GET path uses AAAA for IPv6');
        },
    },
    {
        desc => 'both IPv4 and IPv6 success',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
        desc => 'action returns error status',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'mytoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_error()]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/something went wrong/},
        ],
    },
    {
        desc => 'correct auth header sent',
        cfg => {'host.example.com' => {
            protocol => 'hetzner',
            password => 'supersecrettoken',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [404, $j, ['']],
            [200, $j, [action_running()]],
            [200, $j, [action_success()]],
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
            ddclient::nic_hetzner_update(undef, sort(keys(%{$tc->{cfg}})));
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
