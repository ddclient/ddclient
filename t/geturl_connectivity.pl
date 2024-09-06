use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
BEGIN { eval { require ddclient::Test::Fake::HTTPD; 1; } or plan(skip_all => $@); }
use ddclient::t::ip;
my $has_http_daemon_ssl = eval { require HTTP::Daemon::SSL; 1; };
my $http_daemon_supports_ipv6 = eval {
    require HTTP::Daemon;
    HTTP::Daemon->VERSION(6.12);
};

my $certdir = "$ENV{abs_top_srcdir}/t/lib/ddclient/Test/Fake/HTTPD";
$ddclient::globals{'ssl_ca_file'} = "$certdir/dummy-ca-cert.pem";

sub run_httpd {
    my ($ipv6, $ssl) = @_;
    return undef if $ssl && !$has_http_daemon_ssl;
    return undef if $ipv6 && (!$ipv6_supported || !$http_daemon_supports_ipv6);
    my $httpd = ddclient::Test::Fake::HTTPD->new(
        host => $ipv6 ? '::1' : '127.0.0.1',
        scheme => $ssl ? 'https' : 'http',
        daemon_args => {
            SSL_cert_file => "$certdir/dummy-server-cert.pem",
            SSL_key_file => "$certdir/dummy-server-key.pem",
            V6Only => 1,
        },
    );
    $httpd->run(sub {
        # Echo back the full request.
        return [200, ['Content-Type' => 'application/octet-stream'], [$_[0]->as_string()]];
    });
    diag(sprintf("started IPv%s%s server running at %s",
                 $ipv6 ? '6' : '4', $ssl ? ' SSL' : '', $httpd->endpoint()));
    return $httpd;
}

my %httpd = (
    '4' => {'http' => run_httpd(0, 0), 'https' => run_httpd(0, 1)},
    '6' => {'http' => run_httpd(1, 0), 'https' => run_httpd(1, 1)},
);

my @test_cases = (
    {ipv6_opt => 0, server_ipv => '4', client_ipv => ''},
    {ipv6_opt => 0, server_ipv => '4', client_ipv => '4'},
    # IPv* client to a non-SSL IPv6 server is not expected to work unless opt('ipv6') is true
    {ipv6_opt => 0, server_ipv => '6', client_ipv => '6'},

    # Fetch without ssl
    { server_ipv => '4', client_ipv => '' },
    { server_ipv => '4', client_ipv => '4' },
    { server_ipv => '6', client_ipv => '' },
    { server_ipv => '6', client_ipv => '6' },

    # Fetch with ssl
    { ssl => 1, server_ipv => '4', client_ipv => '' },
    { ssl => 1, server_ipv => '4', client_ipv => '4' },
    { ssl => 1, server_ipv => '6', client_ipv => '' },
    { ssl => 1, server_ipv => '6', client_ipv => '6' },
);

for my $tc (@test_cases) {
    $tc->{ipv6_opt} //= 0;
    $tc->{ssl} //= 0;
    SKIP: {
        skip("IPv6 not supported on this system", 1)
            if $tc->{server_ipv} eq '6' && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1)
            if $tc->{server_ipv} eq '6' && !$http_daemon_supports_ipv6;
        skip("HTTP::Daemon::SSL not available", 1) if $tc->{ssl} && !$has_http_daemon_ssl;
        my $uri = $httpd{$tc->{server_ipv}}{$tc->{ssl} ? 'https' : 'http'}->endpoint();
        my $name = sprintf("IPv%s client to %s%s",
                           $tc->{client_ipv} || '*', $uri, $tc->{ipv6_opt} ? ' (-ipv6)' : '');
        $ddclient::globals{'ipv6'} = $tc->{ipv6_opt};
        my $got = ddclient::geturl(url => $uri, ipversion => $tc->{client_ipv});
        isnt($got // '', '', $name);
    }
}

done_testing();
