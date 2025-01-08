use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::ip;

httpd_required();

$ddclient::globals{'ssl_ca_file'} = $ca_file;

for my $ipv ('4', '6') {
    for my $ssl (0, 1) {
        my $httpd = httpd($ipv, $ssl) or next;
        $httpd->run(sub {
            return [200, ['Content-Type' => 'application/octet-stream'], [$_[0]->as_string()]];
        });
    }
}

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
            if $tc->{server_ipv} eq '6' && !$httpd_ipv6_supported;
        skip("HTTP::Daemon::SSL not available", 1) if $tc->{ssl} && !$httpd_ssl_supported;
        my $uri = httpd($tc->{server_ipv}, $tc->{ssl})->endpoint();
        my $name = sprintf("IPv%s client to %s%s",
                           $tc->{client_ipv} || '*', $uri, $tc->{ipv6_opt} ? ' (-ipv6)' : '');
        $ddclient::globals{'ipv6'} = $tc->{ipv6_opt};
        my $got = ddclient::geturl(url => $uri, ipversion => $tc->{client_ipv});
        isnt($got // '', '', $name);
    }
}

done_testing();
