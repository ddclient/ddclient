use Test::More;
use Data::Dumper;
eval {
    require HTTP::Request;
    require HTTP::Response;
    require IO::Socket::IP;
    require IO::Socket::SSL;
    require ddclient::Test::Fake::HTTPD;
} or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

$Data::Dumper::Sortkeys = 1;

my $httpd = ddclient::Test::Fake::HTTPD->new();
$httpd->run(sub {
    my $req = shift;
    # Echo back the full request.
    my $resp = [ 200, [ 'Content-Type' => 'application/octet-stream' ], [ $req->as_string() ] ];
    if ($req->method() ne 'GET') {
        # TODO: Add support for CONNECT to test https via proxy.
        $resp->[0] = 501;  # 501 == Not Implemented
    }
    return $resp;
});

my $args;

{
    package InterceptSocket;
    require base;
    base->import(qw(IO::Socket::IP));

    sub new {
        my ($class, %args) = @_;
        $args = \%args;
        return $class->SUPER::new(%args, PeerAddr => $httpd->host(), PeerPort => $httpd->port());
    }
}

# Keys:
#   * name: Display name.
#   * params: Parameters to pass to geturl.
#   * opt_ssl: Value to return from opt('ssl'). Defaults to 0.
#   * opt_ssl_ca_dir: Value to return from opt('ssl_ca_dir'). Defaults to undef.
#   * opt_ssl_ca_file: Value to return from opt('ssl_ca_file'). Defaults to undef.
#   * want_args: Args that should be passed to the socket constructor minus MultiHomed, Proto,
#     Timeout, and original_socket_class.
#   * want_req_method: The HTTP method geturl is expected to use. Defaults to 'GET'.
#   * want_req_uri: URI that geturl is expected to request.
#   * todo: If defined, mark this test as expected to fail.
my @test_cases = (
    {
        name => 'https',
        params => {
            url => 'https://hostname',
        },
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '443',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'http with ssl=true',
        params => {
            url => 'http://hostname',
        },
        opt_ssl => 1,
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '443',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'https with port',
        params => {
            url => 'https://hostname:123',
        },
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '123',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'http with port and ssl=true',
        params => {
            url => 'https://hostname:123',
        },
        opt_ssl => 1,
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '123',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'https proxy, http URL',
        params => {
            proxy => 'https://proxy',
            url => 'http://hostname',
        },
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '443',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => 'http://hostname/',
        todo => "broken",
    },
    {
        name => 'http proxy, https URL',
        params => {
            proxy => 'http://proxy',
            url => 'https://hostname',
        },
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '80',
            SSL_startHandshake => 0,
        },
        want_req_method => 'CONNECT',
        want_req_uri => 'hostname:443',
        todo => "not yet supported; silently fails",
    },
    {
        name => 'https proxy, https URL',
        params => {
            proxy => 'https://proxy',
            url => 'https://hostname',
        },
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '443',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_method => 'CONNECT',
        want_req_uri => 'hostname:443',
        todo => "not yet supported; silently fails",
    },
    {
        name => 'http proxy, http URL, ssl=true',
        params => {
            proxy => 'http://proxy',
            url => 'http://hostname',
        },
        opt_ssl => 1,
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '443',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_method => 'CONNECT',
        want_req_uri => 'hostname:443',
        todo => "not yet supported; silently fails",
    },
    {
        name => 'https proxy with port, http URL with port',
        params => {
            proxy => 'https://proxy:123',
            url => 'http://hostname:456',
        },
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '123',
        },
        want_req_uri => 'http://hostname:456/',
        todo => "broken",
    },
    {
        name => 'http proxy with port, https URL with port',
        params => {
            proxy => 'http://proxy:123',
            url => 'https://hostname:456',
        },
        want_args => {
            PeerAddr => 'proxy',
            PeerPort => '123',
            SSL_startHandshake => 0,
        },
        want_req_method => 'CONNECT',
        want_req_uri => 'hostname:456',
        todo => "not yet supported; silently fails",
    },
    {
        name => 'CA dir',
        params => {
            url => 'https://hostname',
        },
        opt_ssl_ca_dir => '/ca/dir',
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '443',
            SSL_ca_path => '/ca/dir',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'CA file',
        params => {
            url => 'https://hostname',
        },
        opt_ssl_ca_file => '/ca/file',
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '443',
            SSL_ca_file => '/ca/file',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
    {
        name => 'CA dir and file',
        params => {
            url => 'https://hostname',
        },
        opt_ssl_ca_dir => '/ca/dir',
        opt_ssl_ca_file => '/ca/file',
        want_args => {
            PeerAddr => 'hostname',
            PeerPort => '443',
            SSL_ca_file => '/ca/file',
            SSL_ca_path => '/ca/dir',
            SSL_verify_mode => IO::Socket::SSL->SSL_VERIFY_PEER,
        },
        want_req_uri => '/',
    },
);

for my $tc (@test_cases) {
    $args = undef;
    $ddclient::globals{'ssl'} = $tc->{opt_ssl} // 0;
    $ddclient::globals{'ssl_ca_dir'} = $tc->{opt_ssl_ca_dir};
    $ddclient::globals{'ssl_ca_file'} = $tc->{opt_ssl_ca_file};
    my $resp_str = ddclient::geturl(_testonly_socket_class => 'InterceptSocket', %{$tc->{params}});
    TODO: {
        local $TODO = $tc->{todo};
        subtest $tc->{name} => sub {
            my %want_args = (
                MultiHomed => 1,
                Proto => 'tcp',
                Timeout => ddclient::opt('timeout'),
                original_socket_class => 'IO::Socket::SSL',
                %{$tc->{want_args}},
            );
            is(Dumper($args), Dumper(\%want_args), "socket constructor args");
            ok(defined($resp_str), "response is defined") or return;
            ok(my $resp = HTTP::Response->parse($resp_str), "parse response") or return;
            ok(my $req_str = $resp->decoded_content(), "decode request from response") or return;
            ok(my $req = HTTP::Request->parse($req_str), "parse request") or return;
            is($req->method(), $tc->{want_req_method} // 'GET', "request method");
            is($req->uri(), $tc->{want_req_uri}, "request URI");
        };
    }
}

done_testing();
