use Test::More;
eval { require JSON::PP; } or plan(skip_all => $@);
JSON::PP->import(qw(encode_json decode_json));
eval { require 'ddclient'; } or BAIL_OUT($@);
eval { require ddclient::Test::Fake::HTTPD; } or plan(skip_all => $@);
eval { require LWP::UserAgent; } or plan(skip_all => $@);

ddclient::load_json_support('dnsexit2');

my @httpd_requests; # Declare variable specificly used for the httpd process (which cannot be shared with tests).
my $httpd = ddclient::Test::Fake::HTTPD->new();

$httpd->run(sub {
    my ($req) = @_;
    if ($req->uri->as_string eq '/get_requests') {
        return [200, ['Content-Type' => 'application/json'], [encode_json(\@httpd_requests)]];
    } elsif ($req->uri->as_string eq '/reset_requests') {
        @httpd_requests = ();
        return [200, ['Content-Type' => 'application/json'], [encode_json({ message => 'OK' })]];
    }
    my $request_info = {
        method => $req->method,
        uri    => $req->uri->as_string,
        content => $req->content,
        headers => $req->headers->as_string
    };
    push @httpd_requests, $request_info;
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        code => 0,
        message => 'Success'
    })]];
});

diag(sprintf("started IPv4 server running at %s", $httpd->endpoint()));

local $ddclient::globals{verbose} = 1;

my $ua = LWP::UserAgent->new;

sub decode_and_sort_array {
    my ($data) = @_;
    if (!ref $data) {
        $data = decode_json($data);
    }
    @{$data->{update}} = sort { $a->{type} cmp $b->{type} } @{$data->{update}};
    return $data;
}

sub reset_test_data {
    my $response = $ua->get($httpd->endpoint . '/reset_requests');
    die "Failed to reset requests" unless $response->is_success;
}

sub get_requests {
    my $res = $ua->get($httpd->endpoint . '/get_requests');
    die "Failed to get requests: " . $res->status_line unless $res->is_success;
    return @{decode_json($res->decoded_content)};
}

subtest 'Testing nic_dnsexit2_update' => sub {
    local %ddclient::config = (
        'host.my.zone.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '8.8.4.4',
            'usev6'    => 'ipv6',
            'wantipv6' => '2001:4860:4860::8888',
            'protocol' => 'dnsexit2',
            'password' => 'mytestingpassword',
            'zone'     => 'my.zone.com',
            'server'   => $httpd->endpoint(),
            'path'     => '/update',
            'ttl'      => 5
    });
    ddclient::nic_dnsexit2_update(undef, 'host.my.zone.com');
    my @requests = get_requests();
    is(scalar(@requests), 1, 'expected number of update requests');
    my $req = shift(@requests);
    is($req->{method}, 'POST', 'Method is correct');
    is($req->{uri}, '/update', 'URI contains correct path');
    like($req->{headers}, qr/Content-Type: application\/json/, 'Content-Type header is correct');
    like($req->{headers}, qr/Accept: application\/json/, 'Accept header is correct');
    my $got = decode_and_sort_array($req->{content});
    my $want = decode_and_sort_array({
        'domain'     => 'my.zone.com',
        'apikey'     => 'mytestingpassword',
        'update' => [
            {
                'type' => 'A',
                'name' => 'host',
                'content' => '8.8.4.4',
                'ttl' => 5,
            },
            {
                'type' => 'AAAA',
                'name' => 'host',
                'content' => '2001:4860:4860::8888',
                'ttl' => 5,
            }
        ]
    });
    is_deeply($got, $want, 'Data is correct');
    reset_test_data();
};

subtest 'Testing nic_dnsexit2_update without a zone set' => sub {
    local %ddclient::config = (
        'myhost.zone.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '8.8.4.4',
            'protocol' => 'dnsexit2',
            'password' => 'anotherpassword',
            'server'   => $httpd->endpoint(),
            'path'     => '/update-alt',
            'ttl'      => 10
    });
    ddclient::nic_dnsexit2_update(undef, 'myhost.zone.com');
    my @requests = get_requests();
    is(scalar(@requests), 1, 'expected number of update requests');
    my $req = shift(@requests);
    my $got = decode_and_sort_array($req->{content});
    my $want = decode_and_sort_array({
        'domain'     => 'myhost.zone.com',
        'apikey'     => 'anotherpassword',
        'update' => [
            {
                'type' => 'A',
                'name' => '',
                'content' => '8.8.4.4',
                'ttl' => 10,
            }
        ]
    });
    is_deeply($got, $want, 'Data is correct');
    reset_test_data($ua);
};

subtest 'Testing nic_dnsexit2_update with two hostnames, one with a zone and one without' => sub {
    local %ddclient::config = (
        'host1.zone.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '8.8.4.4',
            'protocol' => 'dnsexit2',
            'password' => 'testingpassword',
            'server'   => $httpd->endpoint(),
            'path'     => '/update',
            'ttl'      => 5
        },
        'host2.zone.com' => {
            'usev6'    => 'ipv6',
            'wantipv6' => '2001:4860:4860::8888',
            'protocol' => 'dnsexit2',
            'password' => 'testingpassword',
            'server'   => $httpd->endpoint(),
            'path'     => '/update',
            'ttl'      => 10,
            'zone'     => 'zone.com'
        }
    );
    ddclient::nic_dnsexit2_update(undef, 'host1.zone.com', 'host2.zone.com');
    my @requests = get_requests();
    my @got = map(decode_and_sort_array($_->{content}), @requests);
    my @want = (
        decode_and_sort_array({
            'domain' => 'host1.zone.com',
            'apikey' => 'testingpassword',
            'update' => [{
                'type' => 'A',
                'name' => '',
                'content' => '8.8.4.4',
                'ttl' => 5,
            }],
        }),
        decode_and_sort_array({
            'domain' => 'zone.com',
            'apikey' => 'testingpassword',
            'update' => [{
                'type' => 'AAAA',
                'name' => 'host2',
                'content' => '2001:4860:4860::8888',
                'ttl' => 10,
            }],
        }),
    );
    is_deeply(\@got, \@want, 'data is correct');
    reset_test_data();
};

done_testing();
