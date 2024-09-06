use Test::More;
eval { require JSON::PP; } or plan(skip_all => $@);
JSON::PP->import(qw(encode_json));
eval { require ddclient::Test::Fake::HTTPD; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

ddclient::load_json_support('directnic');

my $httpd = ddclient::Test::Fake::HTTPD->new();
$httpd->run(sub {
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
diag("started IPv4 HTTP server running at " . $httpd->endpoint());

{
    package Logger;
    use parent qw(-norequire ddclient::Logger);
    sub new {
        my ($class, $parent) = @_;
        my $self = $class->SUPER::new(undef, $parent);
        $self->{logs} = [];
        return $self;
    }
    sub _log {
        my ($self, $args) = @_;
        push(@{$self->{logs}}, $args)
            if ($args->{label} // '') =~ qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/;
        return $self->SUPER::_log($args);
    }
}

my $hostname = $httpd->endpoint();
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
    my $l = Logger->new($ddclient::_l);
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
