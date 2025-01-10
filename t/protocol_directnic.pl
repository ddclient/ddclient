use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::Logger;

httpd_required();

ddclient::load_json_support('directnic');

httpd()->run(sub {
    my ($req) = @_;
    diag('==============================================================================');
    diag("Test server received request:\n" . $req->as_string());
    my $headers = ['content-type' => 'text/plain; charset=utf-8'];
    if ($req->uri->as_string =~ m/\/dns\/gateway\/(abc|def)\/\?data=([^&]*)/) {
        return [200, ['Content-Type' => 'application/json'], [encode_json({
            result  => 'success',
            message => "Your record was updated to $2",
        })]];
    } elsif ($req->uri->as_string =~ m/\/dns\/gateway\/bad_token\/\?data=([^&]*)/) {
        return [200, ['Content-Type' => 'application/json'], [encode_json({
            result  => 'error',
            message => "There was an error updating your record.",
        })]];
    } elsif ($req->uri->as_string =~ m/\/bad\/path\/\?data=([^&]*)/) {
        return [200, ['Content-Type' => 'application/json'], ['unexpected response body']];
    }
    return [400, $headers, ['unexpected request: ' . $req->uri()]]
});

my $hostname = httpd()->endpoint();
my @test_cases = (
    {
        desc => 'IPv4, good',
        cfg => {h1 => {urlv4 => "$hostname/dns/gateway/abc/", wantipv4 => '192.0.2.1'}},
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
        ],
    },
    {
        desc => 'IPv4, failed',
        cfg => {h1 => {urlv4 => "$hostname/dns/gateway/bad_token/", wantipv4 => '192.0.2.1'}},
        wantrecap => {
            h1 => {'status-ipv4' => 'failed'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/There was an error updating your record/},
        ],
    },
    {
        desc => 'IPv4, bad',
        cfg => {h1 => {urlv4 => "$hostname/bad/path/", wantipv4 => '192.0.2.1'}},
        wantrecap => {
            h1 => {'status-ipv4' => 'bad'},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/response is not a JSON object:\nunexpected response body/},
        ],
    },
    {
        desc => 'IPv4, unexpected response',
        cfg => {h1 => {urlv4 => "$hostname/unexpected/path/", wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/400 Bad Request/},
        ],
    },
    {
        desc => 'IPv4, no urlv4',
        cfg => {h1 => {wantipv4 => '192.0.2.1'}},
        wantrecap => {},
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/missing urlv4 option/},
        ],
    },
    {
        desc => 'IPv6, good',
        cfg => {h1 => {urlv6 => "$hostname/dns/gateway/abc/", wantipv6 => '2001:db8::1'}},
        wantrecap => {
            h1 => {'status-ipv6' => 'good', 'ipv6' => '2001:db8::1', 'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'IPv4 and IPv6, good',
        cfg => {h1 => {
            urlv4 => "$hostname/dns/gateway/abc/",
            urlv6 => "$hostname/dns/gateway/def/",
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        wantrecap => {
            h1 => {'status-ipv4' => 'good', 'ipv4' => '192.0.2.1',
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv4/},
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv6/},
        ],
    },
    {
        desc => 'IPv4 and IPv6, mixed success',
        cfg => {h1 => {
            urlv4 => "$hostname/dns/gateway/bad_token/",
            urlv6 => "$hostname/dns/gateway/def/",
            wantipv4 => '192.0.2.1',
            wantipv6 => '2001:db8::1',
        }},
        wantips => {h1 => {wantipv4 => '192.0.2.1', wantipv6 => '2001:db8::1'}},
        wantrecap => {
            h1 => {'status-ipv4' => 'failed',
                'status-ipv6' => 'good', 'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now},
        },
        wantlogs => [
            {label => 'FAILED', ctx => ['h1'], msg => qr/There was an error updating your record/},
            {label => 'SUCCESS', ctx => ['h1'], msg => qr/IPv6/},
        ],
    },
);

for my $tc (@test_cases) {
    diag('==============================================================================');
    diag("Starting test: $tc->{desc}");
    diag('==============================================================================');
    local $ddclient::globals{debug} = 1;
    local $ddclient::globals{verbose} = 1;
    my $l = ddclient::t::Logger->new($ddclient::_l, qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/);
    local %ddclient::config = %{$tc->{cfg}};
    local %ddclient::recap;
    {
        local $ddclient::_l = $l;
        ddclient::nic_directnic_update(undef, sort(keys(%{$tc->{cfg}})));
    }
    is_deeply(\%ddclient::recap, $tc->{wantrecap}, "$tc->{desc}: recap")
        or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{wantrecap}],
                               Names => ['*got', '*want']));
    $tc->{wantlogs} //= [];
    subtest("$tc->{desc}: logs" => sub {
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
}

done_testing();
