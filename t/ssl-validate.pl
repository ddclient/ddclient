use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require HTTP::Daemon::SSL; 1; } or plan(skip_all => $@); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
BEGIN { eval { require ddclient::Test::Fake::HTTPD; 1; } or plan(skip_all => $@); }
my $ipv6_supported = eval {
    require IO::Socket::IP;
    my $ipv6_socket = IO::Socket::IP->new(
        Domain => 'PF_INET6',
        LocalHost => '::1',
        Listen => 1,
    );
    defined($ipv6_socket);
};
my $http_daemon_supports_ipv6 = eval {
    require HTTP::Daemon;
    HTTP::Daemon->VERSION(6.12);
};

# Note: $ddclient::globals{'ssl_ca_file'} is intentionally NOT set to "$certdir/dummy-ca-cert.pem"
# so that we can test what happens when certificate validation fails.
my $certdir = "$ENV{abs_top_srcdir}/t/lib/ddclient/Test/Fake/HTTPD";

sub run_httpd {
    my ($ipv6) = @_;
    return undef if $ipv6 && (!$ipv6_supported || !$http_daemon_supports_ipv6);
    my $addr = $ipv6 ? '::1' : '127.0.0.1';
    my $httpd = ddclient::Test::Fake::HTTPD->new(
        host => $addr,
        scheme => 'https',
        daemon_args => {
            SSL_cert_file => "$certdir/dummy-server-cert.pem",
            SSL_key_file => "$certdir/dummy-server-key.pem",
            V6Only => 1,
        },
    );
    $httpd->run(sub {
        return [200, ['Content-Type' => 'text/plain'], [$addr]];
    });
    diag(sprintf("started IPv%s SSL server running at %s", $ipv6 ? '6' : '4', $httpd->endpoint()));
    return $httpd;
}
my $h = 't/ssl-validate.pl';
my %httpd = (
    '4' => run_httpd(0),
    '6' => run_httpd(1),
);
my %ep = (
    '4' => $httpd{'4'}->endpoint(),
    '6' => $httpd{'6'} ? $httpd{'6'}->endpoint() : undef,
);

my @test_cases = (
    {
        desc => 'usev4=webv4 web-ssl-validate=no',
        cfg => {'usev4' => 'webv4', 'web-ssl-validate' => 0, 'webv4' => $ep{'4'}},
        want => '127.0.0.1',
    },
    {
        desc => 'usev4=webv4 web-ssl-validate=yes',
        cfg => {'usev4' => 'webv4', 'web-ssl-validate' => 1, 'webv4' => $ep{'4'}},
        want => undef,
    },
    {
        desc => 'usev6=webv6 web-ssl-validate=no',
        cfg => {'usev6' => 'webv6', 'web-ssl-validate' => 0, 'webv6' => $ep{'6'}},
        ipv6 => 1,
        want => '::1',
    },
    {
        desc => 'usev6=webv6 web-ssl-validate=yes',
        cfg => {'usev6' => 'webv6', 'web-ssl-validate' => 1, 'webv6' => $ep{'6'}},
        ipv6 => 1,
        want => undef,
    },
    {
        desc => 'usev4=cisco-asa fw-ssl-validate=no',
        cfg => {'usev4' => 'cisco-asa', 'fw-ssl-validate' => 0,
                # cisco-asa adds https:// to the URL.  :-/
                'fwv4' => substr($ep{'4'}, length('https://'))},
        want => '127.0.0.1',
    },
    {
        desc => 'usev4=cisco-asa fw-ssl-validate=yes',
        cfg => {'usev4' => 'cisco-asa', 'fw-ssl-validate' => 1,
                # cisco-asa adds https:// to the URL.  :-/
                'fwv4' => substr($ep{'4'}, length('https://'))},
        want => undef,
    },
    {
        desc => 'usev4=fwv4 fw-ssl-validate=no',
        cfg => {'usev4' => 'fwv4', 'fw-ssl-validate' => 0, 'fwv4' => $ep{'4'}},
        want => '127.0.0.1',
    },
    {
        desc => 'usev4=fwv4 fw-ssl-validate=yes',
        cfg => {'usev4' => 'fwv4', 'fw-ssl-validate' => 1, 'fwv4' => $ep{'4'}},
        want => undef,
    },
);

for my $tc (@test_cases) {
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1)
            if $tc->{ipv6} && !$http_daemon_supports_ipv6;
        $ddclient::config{$h} = $tc->{cfg};
        %ddclient::config if 0;  # suppress spurious warning "Name used only once: possible typo"
        is(ddclient::get_ipv4($tc->{cfg}{usev4}, $h), $tc->{want}, $tc->{desc})
            if ($tc->{cfg}{usev4});
        is(ddclient::get_ipv6($tc->{cfg}{usev6}, $h), $tc->{want}, $tc->{desc})
            if ($tc->{cfg}{usev6});
    }
}

done_testing();
