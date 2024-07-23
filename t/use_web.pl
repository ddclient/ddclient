use Test::More;
use Scalar::Util qw(blessed);
eval { require ddclient::Test::Fake::HTTPD; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
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

my $builtinweb = 't/use_web.pl builtinweb';
my $h = 't/use_web.pl hostname';

sub run_httpd {
    my ($ipv) = @_;
    return undef if $ipv eq '6' && (!$ipv6_supported || !$http_daemon_supports_ipv6);
    my $httpd = ddclient::Test::Fake::HTTPD->new(
        host => $ipv eq '4' ? '127.0.0.1' : '::1',
        daemon_args => {V6Only => 1},
    );
    my $headers = [
        'content-type' => 'text/plain',
        'this-ipv4-should-be-ignored' => 'skip skip2 192.0.2.255',
        'this-ipv6-should-be-ignored' => 'skip skip2 2001:db8::ff',
    ];
    my $content = $ipv eq '4'
        ? '192.0.2.1 skip 192.0.2.2 skip2 192.0.2.3'
        : '2001:db8::1 skip 2001:db8::2 skip2 2001:db8::3';
    $httpd->run(sub { return [200, $headers, [$content]]; });
    diag("started IPv$ipv server running at ${\($httpd->endpoint())}");
    return $httpd;
}
my %httpd = (
    '4' => run_httpd('4'),
    '6' => run_httpd('6'),
);
my %ep = (
    '4' => $httpd{'4'}->endpoint(),
    '6' => $httpd{'6'} ? $httpd{'6'}->endpoint() : undef,
);

my @test_cases;
for my $ipv ('4', '6') {
    my $ipv4 = $ipv eq '4';
    for my $sfx ('', "v$ipv") {
        push(
            @test_cases,
            {
                desc => "use$sfx=web$sfx web$sfx=<url> IPv$ipv",
                ipv6 => !$ipv4,
                cfg => {"use$sfx" => "web$sfx", "web$sfx" => $ep{$ipv}},
                want => $ipv4 ? '192.0.2.1' : '2001:db8::1',
            },
            {
                desc => "use$sfx=web$sfx web$sfx=<url> web$sfx-skip=skip IPv$ipv",
                ipv6 => !$ipv4,
                cfg => {"use$sfx" => "web$sfx", "web$sfx" => $ep{$ipv}, "web$sfx-skip" => 'skip'},
                # Note that "skip" should skip past the first "skip" and not past "skip2".
                want => $ipv4 ? '192.0.2.2' : '2001:db8::2',
            },
            {
                desc => "use$sfx=web$sfx web$sfx=<builtinweb> IPv$ipv",
                ipv6 => !$ipv4,
                cfg => {"use$sfx" => "web$sfx", "web$sfx" => $builtinweb},
                biw => {url => $ep{$ipv}},
                want => $ipv4 ? '192.0.2.1' : '2001:db8::1',
            },
            {
                desc => "use$sfx=web$sfx web$sfx=<builtinweb w/skip> IPv$ipv",
                ipv6 => !$ipv4,
                cfg => {"use$sfx" => "web$sfx", "web$sfx" => $builtinweb},
                biw => {url => $ep{$ipv}, skip => 'skip'},
                # Note that "skip" should skip past the first "skip" and not past "skip2".
                want => $ipv4 ? '192.0.2.2' : '2001:db8::2',
            },
            {
                desc => "use$sfx=web$sfx web$sfx=<builtinweb w/skip> web$sfx-skip=skip2 IPv$ipv",
                ipv6 => !$ipv4,
                cfg => {"use$sfx" => "web$sfx", "web$sfx" => $builtinweb, "web$sfx-skip" => 'skip2'},
                biw => {url => $ep{$ipv}, skip => 'skip'},
                want => $ipv4 ? '192.0.2.3' : '2001:db8::3',
            },
        );
    }
}

for my $tc (@test_cases) {
    my $subst = sub {
        return map({
            my $class = blessed($_);
            (defined($class) && $class->isa('EndpointPlaceholder')) ? do {
                my $uri = ${$_}->clone();
                $uri->query_param(tc => $tc->{desc});
                $uri;
            } : $_;
        } @_);
    };
    local $ddclient::builtinweb{$builtinweb} = $tc->{biw};
    $ddclient::builtinweb if 0;
    local $ddclient::config{$h} = $tc->{cfg};
    $ddclient::config if 0;
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1)
            if $tc->{ipv6} && !$http_daemon_supports_ipv6;
        is(ddclient::get_ip($tc->{cfg}{use}, $h), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{use};
        is(ddclient::get_ipv4($tc->{cfg}{usev4}, $h), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{usev4};
        is(ddclient::get_ipv6($tc->{cfg}{usev6}, $h), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{usev6};
    }
}

done_testing();
