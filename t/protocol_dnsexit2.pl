use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
BEGIN {
    eval { require ddclient::t::HTTPD; 1; } or plan(skip_all => $@);
    ddclient::t::HTTPD->import();
}

ddclient::load_json_support('dnsexit2');

httpd()->run(sub {
    my ($req) = @_;
    return undef if $req->uri()->path() eq '/control';
    return [200, ['Content-Type' => 'application/json'], [encode_json({
        code => 0,
        message => 'Success'
    })]];
});

local $ddclient::globals{verbose} = 1;

sub decode_and_sort_array {
    my ($data) = @_;
    if (!ref $data) {
        $data = decode_json($data);
    }
    @{$data->{update}} = sort { $a->{type} cmp $b->{type} } @{$data->{update}};
    return $data;
}

subtest 'Testing nic_dnsexit2_update' => sub {
    httpd()->reset();
    local %ddclient::config = (
        'host.my.example.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '192.0.2.1',
            'usev6'    => 'ipv6',
            'wantipv6' => '2001:db8::1',
            'protocol' => 'dnsexit2',
            'password' => 'mytestingpassword',
            'zone'     => 'my.example.com',
            'server'   => httpd()->endpoint(),
            'path'     => '/update',
            'ttl'      => 5
    });
    ddclient::nic_dnsexit2_update(undef, 'host.my.example.com');
    my @requests = httpd()->reset();
    is(scalar(@requests), 1, 'expected number of update requests');
    my $req = shift(@requests);
    is($req->method(), 'POST', 'Method is correct');
    is($req->uri()->as_string(), '/update', 'URI contains correct path');
    is($req->header('content-type'), 'application/json', 'Content-Type header is correct');
    is($req->header('accept'), 'application/json', 'Accept header is correct');
    my $got = decode_and_sort_array($req->content());
    my $want = decode_and_sort_array({
        'domain'     => 'my.example.com',
        'apikey'     => 'mytestingpassword',
        'update' => [
            {
                'type' => 'A',
                'name' => 'host',
                'content' => '192.0.2.1',
                'ttl' => 5,
            },
            {
                'type' => 'AAAA',
                'name' => 'host',
                'content' => '2001:db8::1',
                'ttl' => 5,
            }
        ]
    });
    is_deeply($got, $want, 'Data is correct');
};

subtest 'Testing nic_dnsexit2_update without a zone set' => sub {
    httpd()->reset();
    local %ddclient::config = (
        'myhost.example.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '192.0.2.1',
            'protocol' => 'dnsexit2',
            'password' => 'anotherpassword',
            'server'   => httpd()->endpoint(),
            'path'     => '/update-alt',
            'ttl'      => 10
    });
    ddclient::nic_dnsexit2_update(undef, 'myhost.example.com');
    my @requests = httpd()->reset();
    is(scalar(@requests), 1, 'expected number of update requests');
    my $req = shift(@requests);
    my $got = decode_and_sort_array($req->content());
    my $want = decode_and_sort_array({
        'domain'     => 'myhost.example.com',
        'apikey'     => 'anotherpassword',
        'update' => [
            {
                'type' => 'A',
                'name' => '',
                'content' => '192.0.2.1',
                'ttl' => 10,
            }
        ]
    });
    is_deeply($got, $want, 'Data is correct');
};

subtest 'Testing nic_dnsexit2_update with two hostnames, one with a zone and one without' => sub {
    httpd()->reset();
    local %ddclient::config = (
        'host1.example.com' => {
            'usev4'    => 'ipv4',
            'wantipv4' => '192.0.2.1',
            'protocol' => 'dnsexit2',
            'password' => 'testingpassword',
            'server'   => httpd()->endpoint(),
            'path'     => '/update',
            'ttl'      => 5
        },
        'host2.example.com' => {
            'usev6'    => 'ipv6',
            'wantipv6' => '2001:db8::1',
            'protocol' => 'dnsexit2',
            'password' => 'testingpassword',
            'server'   => httpd()->endpoint(),
            'path'     => '/update',
            'ttl'      => 10,
            'zone'     => 'example.com'
        }
    );
    ddclient::nic_dnsexit2_update(undef, 'host1.example.com', 'host2.example.com');
    my @requests = httpd()->reset();
    my @got = map(decode_and_sort_array($_->content()), @requests);
    my @want = (
        decode_and_sort_array({
            'domain' => 'host1.example.com',
            'apikey' => 'testingpassword',
            'update' => [{
                'type' => 'A',
                'name' => '',
                'content' => '192.0.2.1',
                'ttl' => 5,
            }],
        }),
        decode_and_sort_array({
            'domain' => 'example.com',
            'apikey' => 'testingpassword',
            'update' => [{
                'type' => 'AAAA',
                'name' => 'host2',
                'content' => '2001:db8::1',
                'ttl' => 10,
            }],
        }),
    );
    is_deeply(\@got, \@want, 'data is correct');
};

done_testing();
