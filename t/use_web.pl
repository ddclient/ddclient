use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::ip;

httpd_required();

my $builtinweb = 't/use_web.pl builtinweb';
my $h = 't/use_web.pl hostname';

my $headers = [
    @$textplain,
    'this-ipv4-should-be-ignored' => 'skip skip2 192.0.2.255',
    'this-ipv6-should-be-ignored' => 'skip skip2 2001:db8::ff',
];
httpd('4')->run(sub { return [200, $headers, ['192.0.2.1 skip 192.0.2.2 skip2 192.0.2.3']]; });
httpd('6')->run(sub { return [200, $headers, ['2001:db8::1 skip 2001:db8::2 skip2 2001:db8::3']]; })
    if httpd('6');
my %ep = (
    '4' => httpd('4')->endpoint(),
    '6' => httpd('6') ? httpd('6')->endpoint() : undef,
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
    local $ddclient::builtinweb{$builtinweb} = $tc->{biw};
    $ddclient::builtinweb if 0;
    local $ddclient::config{$h} = $tc->{cfg};
    $ddclient::config if 0;
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1) if $tc->{ipv6} && !$httpd_ipv6_supported;
        is(ddclient::get_ip(ddclient::strategy_inputs('use', $h)), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{use};
        is(ddclient::get_ipv4(ddclient::strategy_inputs('usev4', $h)), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{usev4};
        is(ddclient::get_ipv6(ddclient::strategy_inputs('usev6', $h)), $tc->{want}, $tc->{desc})
            if $tc->{cfg}{usev6};
    }
}

done_testing();
