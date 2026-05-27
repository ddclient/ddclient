use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('netcup');

my $j = ['Content-Type' => 'application/json'];

sub login_ok {
    encode_json({status => 'success', responsedata => {apisessionid => 'sess-abc123'}});
}
sub login_fail {
    encode_json({status => 'error', shortmessage => 'Authentication failed', longmessage => 'Invalid credentials'});
}
sub dns_records {
    my @recs = @_;
    encode_json({status => 'success', responsedata => {dnsrecords => \@recs}});
}
sub update_ok {
    encode_json({status => 'success', responsedata => {}});
}
sub logout_ok {
    encode_json({status => 'success', responsedata => {}});
}

httpd()->run();

my @test_cases = (
    {
        desc => 'IPv4 success, existing record (update)',
        cfg => {'host.example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'mypass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [login_ok()]],
            [200, $j, [dns_records({id => '99', hostname => 'host', type => 'A',
                                    destination => '10.0.0.1', deleterecord => \0, state => 'yes'})]],
            [200, $j, [update_ok()]],
            [200, $j, [logout_ok()]],
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
            is(scalar(@reqs), 4, '4 requests: login + info + update + logout');
            is($reqs[0]->method(), 'POST', 'all requests are POST');
            my $login = decode_json($reqs[0]->content());
            is($login->{action}, 'login', 'first action is login');
            is($login->{param}{customernumber}, '12345',    'customer number sent');
            is($login->{param}{apikey},         'myapikey', 'api key sent');
            is($login->{param}{apipassword},    'mypass',   'api password sent');
            my $info = decode_json($reqs[1]->content());
            is($info->{action}, 'infoDnsRecords', 'second action is infoDnsRecords');
            is($info->{param}{apisessionid}, 'sess-abc123', 'session id forwarded');
            my $update = decode_json($reqs[2]->content());
            is($update->{action}, 'updateDnsRecords', 'third action is updateDnsRecords');
            my $rec = $update->{param}{dnsrecordset}{dnsrecords}[0];
            is($rec->{id},          '99',        'existing record id preserved');
            is($rec->{hostname},    'host',      'subdomain correct');
            is($rec->{type},        'A',         'record type is A');
            is($rec->{destination}, '192.0.2.1', 'destination is new IP');
            my $logout = decode_json($reqs[3]->content());
            is($logout->{action}, 'logout', 'fourth action is logout');
        },
    },
    {
        desc => 'IPv6 success, no existing record (create)',
        cfg => {'host.example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'mypass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [login_ok()]],
            [200, $j, [dns_records()]],
            [200, $j, [update_ok()]],
            [200, $j, [logout_ok()]],
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
            is(scalar(@reqs), 4, '4 requests: login + info + update + logout');
            my $update = decode_json($reqs[2]->content());
            my $rec = $update->{param}{dnsrecordset}{dnsrecords}[0];
            ok(!defined $rec->{id}, 'no id field when creating new record');
            is($rec->{type},        'AAAA',       'record type is AAAA');
            is($rec->{destination}, '2001:db8::1','destination is IPv6 address');
        },
    },
    {
        desc => 'both IPv4 and IPv6 in one session',
        cfg => {'host.example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'mypass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        responses => [
            [200, $j, [login_ok()]],
            [200, $j, [dns_records()]],
            [200, $j, [update_ok()]],
            [200, $j, [dns_records()]],
            [200, $j, [update_ok()]],
            [200, $j, [logout_ok()]],
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
            is(scalar(@reqs), 6, '6 requests: login + (info+update)*2 + logout');
            my $login  = decode_json($reqs[0]->content());
            my $logout = decode_json($reqs[5]->content());
            is($login->{action},  'login',  'first action is login');
            is($logout->{action}, 'logout', 'last action is logout');
            my $upd4 = decode_json($reqs[2]->content());
            my $upd6 = decode_json($reqs[4]->content());
            is($upd4->{param}{dnsrecordset}{dnsrecords}[0]{type}, 'A',    'first update is A');
            is($upd6->{param}{dnsrecordset}{dnsrecords}[0]{type}, 'AAAA', 'second update is AAAA');
        },
    },
    {
        desc => 'login failure',
        cfg => {'host.example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'wrongpass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [login_fail()]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Invalid credentials/},
        ],
        check_reqs => sub {
            my @reqs = @_;
            is(scalar(@reqs), 1, 'only 1 request: failed login, no further calls');
        },
    },
    {
        desc => 'apex domain — hostname equals zone',
        cfg => {'example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'mypass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [login_ok()]],
            [200, $j, [dns_records({id => '1', hostname => '@', type => 'A',
                                    destination => '10.0.0.1', deleterecord => \0, state => 'yes'})]],
            [200, $j, [update_ok()]],
            [200, $j, [logout_ok()]],
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
            my $update = decode_json($reqs[2]->content());
            my $rec = $update->{param}{dnsrecordset}{dnsrecords}[0];
            is($rec->{hostname}, '@', 'apex uses @ as hostname');
        },
    },
    {
        desc => 'API error on infoDnsRecords',
        cfg => {'host.example.com' => {
            protocol => 'netcup',
            login    => '12345',
            password => 'mypass',
            apikey   => 'myapikey',
            zone     => 'example.com',
            server   => httpd()->endpoint(),
            wantipv4 => '192.0.2.1',
        }},
        responses => [
            [200, $j, [login_ok()]],
            [200, $j, [encode_json({status => 'error', longmessage => 'Zone not found'})]],
            [200, $j, [logout_ok()]],
        ],
        wantrecap => {'host.example.com' => {'status-ipv4' => 'failed'}},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/Zone not found/},
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
            ddclient::nic_netcup_update(undef, sort(keys(%{$tc->{cfg}})));
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
