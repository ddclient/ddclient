use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('dreamhost');

# Start httpd with no custom handler; responses are queued via httpd()->reset().
httpd()->run(undef);

my $hostname = httpd()->endpoint();

sub cfg {
    my (%extra) = @_;
    return {
        server   => $hostname,
        password => 'MY-API-KEY',
        %extra,
    };
}

sub list_response {
    my @records = @_;
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({result => 'success', data => \@records})]];
}

sub success_response {
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({result => 'success'})]];
}

sub error_response {
    my ($msg) = @_;
    $msg //= 'record not found';
    return [200, ['Content-Type' => 'application/json'],
            [encode_json({result => 'error', data => $msg})]];
}

sub http_error_response {
    return [500, ['Content-Type' => 'text/plain'], ['Internal Server Error']];
}

my @test_cases = (
    {
        desc => 'IPv4 update: no existing record, add new',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            list_response(),     # list returns empty data array
            success_response(),  # add succeeds
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 2,
        wantcmds  => ['dns-list_records', 'dns-add_record'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
    },
    {
        desc => 'IPv4 update: old record with different IP, remove then add',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.2'),
        },
        responses => [
            list_response({record => 'myhost.example.com', type => 'A',
                           value => '192.0.2.1', zone => 'example.com',
                           editable => '1', comment => ''}),
            success_response(),  # remove succeeds
            success_response(),  # add succeeds
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.2',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 3,
        wantcmds  => ['dns-list_records', 'dns-remove_record', 'dns-add_record'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.2/},
        ],
    },
    {
        desc => 'IPv4: same IP already set, no-op',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            list_response({record => 'myhost.example.com', type => 'A',
                           value => '192.0.2.1', zone => 'example.com',
                           editable => '1', comment => ''}),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 1,
        wantcmds  => ['dns-list_records'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address was already set to 192\.0\.2\.1/},
        ],
    },
    {
        desc => 'IPv6 update: no existing record, add new',
        cfg => {
            'myhost.example.com' => cfg(wantipv6 => '2001:db8::1'),
        },
        responses => [
            list_response(),     # list returns empty
            success_response(),  # add succeeds
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 2,
        wantcmds  => ['dns-list_records', 'dns-add_record'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
    },
    {
        desc => 'IPv6: same IP already set, no-op',
        cfg => {
            'myhost.example.com' => cfg(wantipv6 => '2001:db8::1'),
        },
        responses => [
            list_response({record => 'myhost.example.com', type => 'AAAA',
                           value => '2001:db8::1', zone => 'example.com',
                           editable => '1', comment => ''}),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 1,
        wantcmds  => ['dns-list_records'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address was already set to 2001:db8::1/},
        ],
    },
    {
        desc => 'dual-stack: both IPv4 and IPv6 updated',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::1'),
        },
        responses => [
            list_response(),     # IPv4 list: empty
            success_response(),  # IPv4 add
            list_response(),     # IPv6 list: empty
            success_response(),  # IPv6 add
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'status-ipv6' => 'good',
                'ipv6'        => '2001:db8::1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 4,
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv6 address set to 2001:db8::1/},
        ],
    },
    {
        desc => 'API error on dns-list_records',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            error_response('authentication failed'),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'failed',
            },
        },
        wantreqs  => 1,
        wantcmds  => ['dns-list_records'],
        wantlogs  => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/dns-list_records failed/},
        ],
    },
    {
        desc => 'HTTP error on list request',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            http_error_response(),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'failed',
            },
        },
        wantreqs  => 1,
        wantlogs  => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/500/},
        ],
    },
    {
        desc => 'API error on dns-remove_record',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.2'),
        },
        responses => [
            list_response({record => 'myhost.example.com', type => 'A',
                           value => '192.0.2.1', zone => 'example.com',
                           editable => '1', comment => ''}),
            error_response('cannot remove record'),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'failed',
            },
        },
        wantreqs  => 2,
        wantcmds  => ['dns-list_records', 'dns-remove_record'],
        wantlogs  => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/dns-remove_record failed/},
        ],
    },
    {
        desc => 'API error on dns-add_record',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            list_response(),
            error_response('record already exists'),
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'failed',
            },
        },
        wantreqs  => 2,
        wantcmds  => ['dns-list_records', 'dns-add_record'],
        wantlogs  => [
            {label => 'FAILED', ctx => ['myhost.example.com'], msg => qr/dns-add_record failed/},
        ],
    },
    {
        desc => 'list response has records for other hosts, ignored',
        cfg => {
            'myhost.example.com' => cfg(wantipv4 => '192.0.2.1'),
        },
        responses => [
            list_response(
                {record => 'other.example.com', type => 'A',
                 value => '10.0.0.1', zone => 'example.com',
                 editable => '1', comment => ''},
                {record => 'myhost.example.com', type => 'AAAA',
                 value => '2001:db8::1', zone => 'example.com',
                 editable => '1', comment => ''},
            ),
            success_response(),  # add A record
        ],
        wantrecap => {
            'myhost.example.com' => {
                'status-ipv4' => 'good',
                'ipv4'        => '192.0.2.1',
                'mtime'       => $ddclient::now,
            },
        },
        wantreqs  => 2,
        wantcmds  => ['dns-list_records', 'dns-add_record'],
        wantlogs  => [
            {label => 'SUCCESS', ctx => ['myhost.example.com'], msg => qr/IPv4 address set to 192\.0\.2\.1/},
        ],
    },
);

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    subtest($tc->{desc} => sub {
        local $ddclient::globals{debug} = 1;
        local $ddclient::globals{verbose} = 1;
        # Queue responses and clear request log.
        httpd()->reset(@{$tc->{responses}});
        local %ddclient::config = %{$tc->{cfg}};
        local %ddclient::recap;
        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        {
            local $ddclient::_l = $l;
            ddclient::nic_dreamhost_update(undef, sort(keys(%{$tc->{cfg}})));
        }
        my @reqs = httpd()->reset();

        is_deeply(\%ddclient::recap, $tc->{wantrecap}, "recap")
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names => ['*got', '*want']));

        if (exists $tc->{wantreqs}) {
            is(scalar(@reqs), $tc->{wantreqs}, "sent $tc->{wantreqs} request(s)");
        }

        if ($tc->{wantcmds}) {
            for my $i (0..$#{$tc->{wantcmds}}) {
                last if $i >= @reqs;
                my $q = $reqs[$i]->uri()->query() // '';
                like($q, qr/cmd=$tc->{wantcmds}[$i]/, "request $i has cmd=$tc->{wantcmds}[$i]");
                is($reqs[$i]->method(), 'GET', "request $i is a GET");
            }
        }

        $tc->{wantlogs} //= [];
        subtest("logs" => sub {
            my @got = @{$l->{logs}};
            my @want = @{$tc->{wantlogs}};
            for my $i (0..$#want) {
                last if $i >= @got;
                my $got = $got[$i];
                my $want = $want[$i];
                subtest("log $i" => sub {
                    is($got->{label}, $want->{label}, "label matches");
                    is_deeply($got->{ctx}, $want->{ctx}, "context matches");
                    like($got->{msg}, $want->{msg}, "message matches");
                }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
            }
            my @unexpected = @got[@want..$#got];
            ok(@unexpected == 0, "no unexpected logs")
                or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
            my @missing = @want[@got..$#want];
            ok(@missing == 0, "no missing logs")
                or diag(ddclient::repr(\@missing, Names => ['*missing']));
        });
    });
}

done_testing();
