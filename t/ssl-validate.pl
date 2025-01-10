use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::ip;

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

httpd_required();
httpd_ssl_required();

httpd('4', 1)->run(sub { return [200, $textplain, ['127.0.0.1']]; });
httpd('6', 1)->run(sub { return [200, $textplain, ['::1']]; }) if httpd('6', 1);
my $h = 't/ssl-validate.pl';
my %ep = (
    '4' => httpd('4', 1)->endpoint(),
    '6' => httpd('6', 1) ? httpd('6', 1)->endpoint() : undef,
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
    local $ddclient::_l = ddclient::pushlogctx($tc->{desc});
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1) if $tc->{ipv6} && !$httpd_ipv6_supported;
        # $ddclient::globals{'ssl_ca_file'} is intentionally NOT set to $ca_file so that we can
        # test what happens when certificate validation fails.  However, if curl can't find any CA
        # certificates (which may be the case in some minimal test environments, such as Docker
        # images and Debian package builder chroots), it will immediately close the connection
        # after it sends the TLS client hello and before it receives the server hello (in Debian
        # sid as of 2025-01-08, anyway).  This confuses IO::Socket::SSL (used by
        # Test::Fake::HTTPD), causing it to hang in the middle of the TLS handshake waiting for
        # input that will never arrive.  To work around this, the CA certificate file is explicitly
        # set to an unrelated certificate so that curl has something to read.
        local $ddclient::globals{'ssl_ca_file'} = $other_ca_file;
        local $ddclient::config{$h} = $tc->{cfg};
        %ddclient::config if 0;  # suppress spurious warning "Name used only once: possible typo"
        is(ddclient::get_ipv4(ddclient::strategy_inputs('usev4', $h)), $tc->{want}, $tc->{desc})
            if ($tc->{cfg}{usev4});
        is(ddclient::get_ipv6(ddclient::strategy_inputs('usev6', $h)), $tc->{want}, $tc->{desc})
            if ($tc->{cfg}{usev6});
    }
}

done_testing();
