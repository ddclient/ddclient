use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('alicloud');

my $j = ['Content-Type' => 'application/json'];

sub list_resp {
    my @records = @_;
    encode_json({DomainRecords => {Record => \@records}});
}

sub record {
    my (%args) = @_;
    return {
        RR       => $args{rr}   // 'myhost',
        RecordId => $args{id}   // 'rec001',
        Line     => $args{line} // 'default',
        Type     => $args{type} // 'A',
    };
}

sub update_resp {
    my ($id) = @_;
    encode_json({RequestId => 'req-001', RecordId => $id // 'rec001'});
}

sub api_error {
    my ($code, $msg) = @_;
    encode_json({Code => $code, Message => $msg});
}

sub query_params {
    my ($req) = @_;
    my %params;
    for my $pair (split(/&/, $req->uri()->query() // '')) {
        my ($k, $v) = split(/=/, $pair, 2);
        s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge for ($k, $v);
        $params{$k} = $v;
    }
    return \%params;
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec001', type => 'A'))]],
            [200, $j, [update_resp('rec001')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 requests: DescribeDomainRecords + UpdateDomainRecord');
            my $lp = query_params($reqs[0]);
            is($lp->{Action},      'DescribeDomainRecords', 'first request is DescribeDomainRecords');
            is($lp->{DomainName},  'example.com',           'DomainName correct');
            is($lp->{RRKeyWord},   'myhost',                'RRKeyWord correct');
            is($lp->{TypeKeyWord}, 'A',                     'TypeKeyWord is A');
            my $up = query_params($reqs[1]);
            is($up->{Action},   'UpdateDomainRecord', 'second request is UpdateDomainRecord');
            is($up->{RecordId}, 'rec001',             'RecordId matches');
            is($up->{RR},       'myhost',             'RR correct');
            is($up->{Type},     'A',                  'Type is A');
            is($up->{Value},    '192.0.2.1',          'Value is new IP');
        },
    },
    {
        desc => 'IPv6 success',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec002', type => 'AAAA'))]],
            [200, $j, [update_resp('rec002')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv6' => 'good',
            'ipv6'        => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 2, '2 requests for IPv6');
            is(query_params($reqs[0])->{TypeKeyWord}, 'AAAA', 'TypeKeyWord is AAAA');
            is(query_params($reqs[1])->{Value},       '2001:db8::1', 'Value is IPv6 address');
        },
    },
    {
        desc => 'dual-stack IPv4 and IPv6',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec001', type => 'A'))]],
            [200, $j, [update_resp('rec001')]],
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec002', type => 'AAAA'))]],
            [200, $j, [update_resp('rec002')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
            'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 4, '4 requests: list+update for each address family');
            is(query_params($reqs[0])->{TypeKeyWord}, 'A',    'first list is for A');
            is(query_params($reqs[2])->{TypeKeyWord}, 'AAAA', 'second list is for AAAA');
        },
    },
    {
        desc => 'custom TTL included in update request',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            ttl      => 600,
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec001', type => 'A'))]],
            [200, $j, [update_resp('rec001')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(query_params($reqs[1])->{TTL}, '600', 'TTL=600 included in UpdateDomainRecord');
        },
    },
    {
        desc => 'zone inferred from hostname when not set',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec001', type => 'A'))]],
            [200, $j, [update_resp('rec001')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            my $lp = query_params($reqs[0]);
            is($lp->{DomainName}, 'example.com', 'DomainName inferred from hostname');
            is($lp->{RRKeyWord},  'myhost',      'RRKeyWord is first component');
        },
    },
    {
        desc => 'root zone update uses @ as subdomain',
        cfg => {'example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => '@', id => 'rec001', type => 'A'))]],
            [200, $j, [update_resp('rec001')]],
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
            is(query_params($reqs[0])->{RRKeyWord}, '@', 'root zone uses @ as RRKeyWord');
            is(query_params($reqs[1])->{RR},        '@', 'root zone uses @ in UpdateDomainRecord');
        },
    },
    {
        desc => 'zone mismatch fails with no requests sent',
        cfg => {'myhost.example.net' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.net'],
             msg => qr/does not end with zone 'example\.com'/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 0, 'no requests sent on zone mismatch');
        },
    },
    {
        desc => 'bare hostname without dot fails with useful error',
        cfg => {'localhostname' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [],
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['localhostname'],
             msg => qr/no dot in hostname.*use zone=/},
        ],
    },
    {
        desc => 'record not found leaves status-ipv4 failed',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp()]],
        ],
        wantrecap => {'myhost.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'],
             msg => qr/no A record found for myhost\.example\.com/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only DescribeDomainRecords sent, no update');
        },
    },
    {
        desc => 'API error in list call leaves status-ipv4 failed',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [api_error('InvalidAccessKeyId', 'Specified access key is not found')]],
        ],
        wantrecap => {'myhost.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'],
             msg => qr/API error \(InvalidAccessKeyId\)/},
        ],
    },
    {
        desc => 'HTTP error on list call leaves status-ipv4 failed',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [500, $j, [encode_json({Code => 'InternalError', Message => 'server error'})]],
        ],
        wantrecap => {'myhost.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/500/},
        ],
    },
    {
        desc => 'API error in update call leaves status-ipv4 failed',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(record(rr => 'myhost', id => 'rec001', type => 'A'))]],
            [200, $j, [api_error('InvalidParameter', 'The parameter Value is invalid')]],
        ],
        wantrecap => {'myhost.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['myhost.example.com'],
             msg => qr/API error \(InvalidParameter\)/},
        ],
    },
    {
        desc => 'multiple matching records logs warning and uses first',
        cfg => {'myhost.example.com' => {
            protocol => 'alicloud',
            login    => 'key1',
            password => 'secret1',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [list_resp(
                record(rr => 'myhost', id => 'rec001', type => 'A'),
                record(rr => 'myhost', id => 'rec002', type => 'A'),
            )]],
            [200, $j, [update_resp('rec001')]],
        ],
        wantrecap => {'myhost.example.com' => {
            'status-ipv4' => 'good',
            'ipv4'        => '192.0.2.1',
            'mtime'       => $ddclient::now,
        }},
        wantlogs => [
            {label => 'WARNING', ctx => ['myhost.example.com'],
             msg => qr/multiple A records found.*using the first one/},
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(query_params($reqs[1])->{RecordId}, 'rec001', 'first record ID used in update');
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
            ddclient::nic_alicloud_update(undef, sort(keys(%{$tc->{cfg}})));
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
