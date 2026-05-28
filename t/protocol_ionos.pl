use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

local $ddclient::globals{debug}   = 1;
local $ddclient::globals{verbose} = 1;

ddclient::load_json_support('ionos');

# Use scripted responses: httpd()->reset(r1, r2, ...) loads the response script
# for the next test, and returns logged requests from the previous test.
httpd()->run(sub { return undef; });  # let all requests fall through to scripted responses

my $a_rec   = {id => 'rec-a',    name => 'host.example.com', type => 'A',
               content => '203.0.113.1', ttl => 300, prio => 0, disabled => \0};
my $aaaa_rec = {id => 'rec-aaaa', name => 'host.example.com', type => 'AAAA',
                content => '2001:db8::1', ttl => 300, prio => 0, disabled => \0};

sub zones_ok  { [200, ['Content-Type', 'application/json'],
                 [encode_json([{id => 'zone-1', name => 'example.com', type => 'NATIVE'}])]] }
sub zones_err { [500, ['Content-Type', 'text/plain'], ['server error']] }
sub records_ok {
    my (@recs) = @_;
    [200, ['Content-Type', 'application/json'],
     [encode_json({id => 'zone-1', name => 'example.com', records => \@recs})]];
}
sub records_err { [500, ['Content-Type', 'text/plain'], ['server error']] }
sub update_ok   { [200, ['Content-Type', 'application/json'], [encode_json({id => 'rec-a'})]] }
sub update_err  { [500, ['Content-Type', 'text/plain'], ['server error']] }

my $hostname = httpd()->endpoint();

my @test_cases = (
    {
        desc => 'IPv4 update, record exists (PUT)',
        responses => [zones_ok(), records_ok($a_rec), update_ok()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 3, 'three requests: zone list, records, PUT');
            return if @reqs < 3;
            is($reqs[0]->method(), 'GET',  'first request is GET (zones)');
            is($reqs[1]->method(), 'GET',  'second request is GET (records)');
            is($reqs[2]->method(), 'PUT',  'third request is PUT (update)');
            like($reqs[2]->uri()->path(), qr{/dns/v1/zones/zone-1/records/rec-a},
                 'PUT targets correct record ID');
            my $body = eval { decode_json($reqs[2]->content()) };
            is(ref($body), 'HASH',      'PUT body is a JSON object');
            is($body->{content}, '192.0.2.1', 'PUT body has correct IP');
            ok(!defined($body->{name}), 'PUT body has no name field');
            ok(!defined($body->{type}), 'PUT body has no type field');
        },
    },
    {
        desc => 'IPv6 update, record exists (PUT)',
        responses => [zones_ok(), records_ok($aaaa_rec), update_ok()],
        cfg => {'host.example.com' => {wantipv6 => '2001:db8::2'}},
        wantrecap => {
            'host.example.com' => {
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::2', 'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6.*2001:db8::2/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 3, 'three requests');
            return if @reqs < 3;
            is($reqs[2]->method(), 'PUT', 'third request is PUT');
            like($reqs[2]->uri()->path(), qr{/records/rec-aaaa}, 'PUT targets AAAA record');
            my $body = eval { decode_json($reqs[2]->content()) };
            is($body->{content}, '2001:db8::2', 'PUT body has correct IPv6');
        },
    },
    {
        desc => 'IPv4 update, no existing record (POST)',
        responses => [zones_ok(), records_ok(), update_ok()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4.*192\.0\.2\.1/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 3, 'three requests');
            return if @reqs < 3;
            is($reqs[2]->method(), 'POST', 'third request is POST (create)');
            like($reqs[2]->uri()->path(), qr{/dns/v1/zones/zone-1/records$},
                 'POST targets zone records endpoint');
            my $body = eval { decode_json($reqs[2]->content()) };
            is(ref($body), 'ARRAY', 'POST body is a JSON array');
            return unless ref($body) eq 'ARRAY' && @$body;
            is($body->[0]{name},    'host.example.com', 'POST body has correct name');
            is($body->[0]{type},    'A',                'POST body has type A');
            is($body->[0]{content}, '192.0.2.1',        'POST body has correct IP');
        },
    },
    {
        desc => 'both IPv4 and IPv6 updated (dual-stack)',
        responses => [zones_ok(), records_ok($a_rec, $aaaa_rec), update_ok(), update_ok()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::2'}},
        wantrecap => {
            'host.example.com' => {
                'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::2',
                'mtime' => $ddclient::now,
            },
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['host.example.com'], msg => qr/IPv6/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 4, 'four requests: zone list, records, PUT x2');
        },
    },
    {
        desc => 'zone not found',
        responses => [[200, ['Content-Type', 'application/json'], [encode_json([])]]],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/no IONOS zone found/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 1, 'only one request (zone list)');
        },
    },
    {
        desc => 'zone list API error',
        responses => [zones_err()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/500/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 1, 'only one request (zone list)');
        },
    },
    {
        desc => 'records API error',
        responses => [zones_ok(), records_err()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/500/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 2, 'two requests: zone list, records');
        },
    },
    {
        desc => 'update API error sets status-ipv4 to failed',
        responses => [zones_ok(), records_ok(), update_err()],
        cfg => {'host.example.com' => {wantipv4 => '192.0.2.1'}},
        wantrecap => {
            'host.example.com' => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['host.example.com'], msg => qr/500/},
        ],
        wantreqs => sub {
            my (@reqs) = @_;
            is(scalar(@reqs), 3, 'three requests: zone list, records, POST');
        },
    },
);

httpd()->reset();  # clear initial state

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    diag('==============================================================================');
    subtest($tc->{desc} => sub {
        # Load responses for this test; discard any stale requests from the last reset.
        httpd()->reset(@{$tc->{responses}});
        my @hosts = keys(%{$tc->{cfg}});
        my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
        local %ddclient::config = ();
        for my $h (@hosts) {
            $ddclient::config{$h} = {
                password => 'test-prefix.test-secret',
                server   => $hostname,
                ssl      => 0,
                %{$tc->{cfg}{$h}},
            };
        }
        local %ddclient::recap;
        {
            local $ddclient::_l = $l;
            ddclient::nic_ionos_update(undef, sort(@hosts));
        }
        my @reqs = httpd()->reset();
        is_deeply(\%ddclient::recap, $tc->{wantrecap}, "recap")
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                                   Names => ['*got', '*want']));
        subtest('logs' => sub {
            my @got  = @{$l->{logs}};
            my @want = @{$tc->{wantlogs} // []};
            for my $i (0..$#want) {
                last if $i >= @got;
                my $got  = $got[$i];
                my $want = $want[$i];
                subtest("log $i" => sub {
                    is($got->{label}, $want->{label}, 'label');
                    is_deeply($got->{ctx}, $want->{ctx}, 'context');
                    like($got->{msg}, $want->{msg}, 'message');
                }) or diag(ddclient::repr(Values => [$got, $want], Names => ['*got', '*want']));
            }
            my @unexpected = @got[@want..$#got];
            ok(!@unexpected, 'no unexpected logs')
                or diag(ddclient::repr(\@unexpected, Names => ['*unexpected']));
            my @missing = @want[@got..$#want];
            ok(!@missing, 'no missing logs')
                or diag(ddclient::repr(\@missing, Names => ['*missing']));
        });
        subtest('requests' => sub { $tc->{wantreqs}->(@reqs) }) if $tc->{wantreqs};
    });
}

done_testing();
