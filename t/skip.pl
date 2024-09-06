use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
BEGIN { eval { require ddclient::Test::Fake::HTTPD; 1; } or plan(skip_all => $@); }
use ddclient::t::ip;
my $http_daemon_supports_ipv6 = eval {
    require HTTP::Daemon;
    HTTP::Daemon->VERSION(6.12);
};

sub run_httpd {
    my ($ipv6) = @_;
    return undef if $ipv6 && (!$ipv6_supported || !$http_daemon_supports_ipv6);
    my $httpd = ddclient::Test::Fake::HTTPD->new(
        host => $ipv6 ? '::1' : '127.0.0.1',
        scheme => 'http',
        daemon_args => {V6Only => 1},
    );
    my $out = $ipv6 ? '::1 skip ::2' : '127.0.0.1 skip 127.0.0.2';
    $httpd->run(sub {
        return [200, ['Content-Type' => 'text/plain'], [$out]];
    });
    diag(sprintf("started IPv%s SSL server running at %s", $ipv6 ? '6' : '4', $httpd->endpoint()));
    return $httpd;
}
my %httpd = (
    '4' => run_httpd(0),
    '6' => run_httpd(1),
);

my $builtinwebv4 = 't/skip.pl webv4';
my $builtinwebv6 = 't/skip.pl webv6';
my $builtinfw = 't/skip.pl fw';

$ddclient::builtinweb{$builtinwebv4} = {'url' => $httpd{'4'}->endpoint(), 'skip' => 'skip'};
$ddclient::builtinweb{$builtinwebv6} = {'url' => $httpd{'6'}->endpoint(), 'skip' => 'skip'}
    if $httpd{'6'};
$ddclient::builtinfw{$builtinfw} = {name => 'test', skip => 'skip'};
%ddclient::builtinfw if 0;  # suppress spurious warning "Name used only once: possible typo"

sub run_test_case {
    my %tc = @_;
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1)
            if $tc{ipv6} && !$http_daemon_supports_ipv6;
        my $h = 't/skip.pl';
        $ddclient::config{$h} = $tc{cfg};
        %ddclient::config if 0;  # suppress spurious warning "Name used only once: possible typo"
        is(ddclient::get_ip($tc{cfg}{use}, $h), $tc{want}, $tc{desc}) if ($tc{cfg}{use});
        is(ddclient::get_ipv4($tc{cfg}{usev4}, $h), $tc{want}, $tc{desc}) if ($tc{cfg}{usev4});
        is(ddclient::get_ipv6($tc{cfg}{usev6}, $h), $tc{want}, $tc{desc}) if ($tc{cfg}{usev6});
    }
}

subtest "use=web web='$builtinwebv4'" => sub {
    run_test_case(
        desc => "web-skip='' cancels built-in skip",
        cfg => {
            'use' => 'web',
            'web' => $builtinwebv4,
            'web-skip' => '',
        },
        want => '127.0.0.1',
    );
    run_test_case(
        desc => 'web-skip=undef uses built-in skip',
        cfg => {
            'use' => 'web',
            'web' => $builtinwebv4,
            'web-skip' => undef,
        },
        want => '127.0.0.2',
    );
};
subtest "usev4=webv4 webv4='$builtinwebv4'" => sub {
    run_test_case(
        desc => "webv4-skip='' cancels built-in skip",
        cfg => {
            'usev4' => 'webv4',
            'webv4' => $builtinwebv4,
            'webv4-skip' => '',
        },
        want => '127.0.0.1',
    );
    run_test_case(
        desc => 'webv4-skip=undef uses built-in skip',
        cfg => {
            'usev4' => 'webv4',
            'webv4' => $builtinwebv4,
            'webv4-skip' => undef,
        },
        want => '127.0.0.2',
    );
};
subtest "usev6=webv6 webv6='$builtinwebv6'" => sub {
    run_test_case(
        desc => "webv6-skip='' cancels built-in skip",
        cfg => {
            'usev6' => 'webv6',
            'webv6' => $builtinwebv6,
            'webv6-skip' => '',
        },
        ipv6 => 1,
        want => '::1',
    );
    run_test_case(
        desc => 'webv6-skip=undef uses built-in skip',
        cfg => {
            'usev6' => 'webv6',
            'webv6' => $builtinwebv6,
            'webv6-skip' => undef,
        },
        ipv6 => 1,
        want => '::2',
    );
};
subtest "use='$builtinfw'" => sub {
    run_test_case(
        desc => "fw-skip='' cancels built-in skip",
        cfg => {
            'fw' => $httpd{'4'}->endpoint(),
            'fw-skip' => '',
            'use' => $builtinfw,
        },
        want => '127.0.0.1',
    );
    run_test_case(
        desc => 'fw-skip=undef uses built-in skip',
        cfg => {
            'fw' => $httpd{'4'}->endpoint(),
            'fw-skip' => undef,
            'use' => $builtinfw,
        },
        want => '127.0.0.2',
    );
};
subtest "usev4='$builtinfw'" => sub {
    run_test_case(
        desc => "fwv4-skip='' cancels built-in skip",
        cfg => {
            'fwv4' => $httpd{'4'}->endpoint(),
            'fwv4-skip' => '',
            'usev4' => $builtinfw,
        },
        want => '127.0.0.1',
    );
    run_test_case(
        desc => 'fwv4-skip=undef uses built-in skip',
        cfg => {
            'fwv4' => $httpd{'4'}->endpoint(),
            'fwv4-skip' => undef,
            'usev4' => $builtinfw,
        },
        want => '127.0.0.2',
    );
};

done_testing();
