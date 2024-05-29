use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

ddclient::load_json_support('dnsexit2');

httpd()->run(sub {
    my ($req) = @_;
    return undef if $req->uri()->path() eq '/control';
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        code => 0,
        message => 'Success'
    })]];
});

sub cmp_update {
    my ($a, $b) = @_;
    return $a->{name} cmp $b->{name} || $a->{type} cmp $b->{type};
}

sub sort_updates {
    my ($req) = @_;
    return {
        %$req,
        update => [sort({ cmp_update($a, $b); } @{$req->{update}})],
    };
}

sub sort_reqs {
    my @reqs = map(sort_updates($_), @_);
    my @sorted = sort({
        my $ret = $a->{domain} cmp $b->{domain};
        $ret = @{$a->{update}} <=> @{$b->{update}} if !$ret;
        my $i = 0;
        while (!$ret && $i < @{$a->{update}} && $i < @{$b->{update}}) {
            $ret = cmp_update($a->{update}[$i], $b->{update}[$i]);
        }
        return $ret;
    } @reqs);
    return @sorted;
}

my @test_cases = (
    {
        desc => 'both IPv4 and IPv6 are updated together',
        cfg => {
            'host.my.example.com' => {
                ttl => 5,
                wantipv4 => '192.0.2.1',
                wantipv6 => '2001:db8::1',
                zone => 'my.example.com',
            },
        },
        want => [{
            apikey => 'key',
            domain => 'my.example.com',
            update => [
                {
                    content => '192.0.2.1',
                    name => 'host',
                    ttl => 5,
                    type => 'A',
                },
                {
                    content => '2001:db8::1',
                    name => 'host',
                    ttl => 5,
                    type => 'AAAA',
                },
            ],
        }],
    },
    {
        desc => 'zone defaults to host',
        cfg => {
            'host.my.example.com' => {
                ttl => 10,
                wantipv4 => '192.0.2.1',
            },
        },
        want => [{
            apikey => 'key',
            domain => 'host.my.example.com',
            update => [
                {
                    content => '192.0.2.1',
                    name => '',
                    ttl => 10,
                    type => 'A',
                },
            ],
        }],
    },
    {
        desc => 'two hosts, different zones',
        cfg => {
            'host1.example.com' => {
                ttl => 5,
                wantipv4 => '192.0.2.1',
                # 'zone' intentionally not set, so it will default to 'host1.example.com'.
            },
            'host2.example.com' => {
                ttl => 10,
                wantipv6 => '2001:db8::1',
                zone => 'example.com',
            },
        },
        want => [
            {
                apikey => 'key',
                domain => 'host1.example.com',
                update => [
                    {
                        content => '192.0.2.1',
                        name => '',
                        ttl => 5,
                        type => 'A',
                    },
                ],
            },
            {
                apikey => 'key',
                domain => 'example.com',
                update => [
                    {
                        content => '2001:db8::1',
                        name => 'host2',
                        ttl => 10,
                        type => 'AAAA',
                    },
                ],
            },
        ],
    },
    {
        desc => 'two hosts, same zone',
        cfg => {
            'host1.example.com' => {
                ttl => 5,
                wantipv4 => '192.0.2.1',
                zone => 'example.com',
            },
            'host2.example.com' => {
                ttl => 10,
                wantipv6 => '2001:db8::1',
                zone => 'example.com',
            },
        },
        want => [
            {
                apikey => 'key',
                domain => 'example.com',
                update => [
                    {
                        content => '192.0.2.1',
                        name => 'host1',
                        ttl => 5,
                        type => 'A',
                    },
                    {
                        content => '2001:db8::1',
                        name => 'host2',
                        ttl => 10,
                        type => 'AAAA',
                    },
                ],
            },
        ],
    },
    {
        desc => 'host outside of zone',
        cfg => {
            'host.example' => {
                wantipv4 => '192.0.2.1',
                zone => 'example.com',
            },
        },
        want_fatal => qr{hostname does not end with the zone: example.com},
    },
);

for my $tc (@test_cases) {
    subtest($tc->{desc} => sub {
        local $ddclient::_l = ddclient::pushlogctx($tc->{desc});
        local %ddclient::config = ();
        my @hosts = keys(%{$tc->{cfg}});
        for my $h (@hosts) {
            $ddclient::config{$h} = {
                password => 'key',
                path => '/update',
                server => httpd()->endpoint(),
                %{$tc->{cfg}{$h}},
            };
        }
        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^FATAL$/);
        my $err = do {
            local $ddclient::_l = $l;
            local $@;
            (eval { ddclient::nic_dnsexit2_update(undef, @hosts); 1; })
                ? undef : ($@ // 'unknown error');
        };
        my @requests = httpd()->reset();
        my @got;
        for (my $i = 0; $i < @requests; $i++) {
            subtest("request $i" => sub {
                my $req = $requests[$i];
                is($req->method(), 'POST', 'method is POST');
                is($req->uri()->as_string(), '/update', 'path is /update');
                is($req->header('content-type'), 'application/json', 'Content-Type is JSON');
                is($req->header('accept'), 'application/json', 'Accept is JSON');
                my $got = decode_json($req->content());
                is(ref($got), 'HASH', 'request content is a JSON object');
                is(ref($got->{update}), 'ARRAY', 'JSON object has array "update" property');
                push(@got, $got);
            });
        }
        @got = sort_reqs(@got);
        my @want = sort_reqs(@{$tc->{want} // []});
        is_deeply(\@got, \@want, 'request objects match');
        subtest('expected (or lack of) error' => sub {
            if (is(defined($err), defined($tc->{want_fatal}), 'error existence') && defined($err)) {
                my @got = @{$l->{logs}};
                if (is(scalar(@got), 2, 'logged two events')) {
                    is($got[0]->{label}, 'FATAL', 'first logged event is a FATAL message');
                    like($got[0]->{msg}, $tc->{want_fatal}, 'first logged event message matches');
                    is($got[1], 'aborted', 'second logged event is an "aborted" event');
                    isa_ok($err, qw(ddclient::t::LoggerAbort));
                }
            }
        });
    });
}

done_testing();
