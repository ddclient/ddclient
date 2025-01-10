use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;

my @test_cases;
for my $ipv ('4', '6') {
    my $ip = $ipv eq '4' ? '192.0.2.1' : '2001:db8::1';
    for my $use ('use', "usev$ipv") {
        my @cmds = ();
        push(@cmds, 'cmd') if $use eq 'use' || $ipv eq '6';
        push(@cmds, "cmdv$ipv") if $use ne 'use';
        for my $cmd (@cmds) {
            my $cmdarg = "echo '$ip'";
            push(
                @test_cases,
                {
                    desc => "$use=$cmd $cmd=\"$cmdarg\"",
                    cfg => {$use => $cmd, $cmd => $cmdarg},
                    want => $ip,
                },
            );
        }
    }
}

for my $tc (@test_cases) {
    local $ddclient::_l = ddclient::pushlogctx($tc->{desc});
    my $h = 'test-host';
    local $ddclient::config{$h} = $tc->{cfg};
    is(ddclient::get_ip(ddclient::strategy_inputs('use', $h)), $tc->{want}, $tc->{desc})
        if $tc->{cfg}{use};
    is(ddclient::get_ipv4(ddclient::strategy_inputs('usev4', $h)), $tc->{want}, $tc->{desc})
        if $tc->{cfg}{usev4};
    is(ddclient::get_ipv6(ddclient::strategy_inputs('usev6', $h)), $tc->{want}, $tc->{desc})
        if $tc->{cfg}{usev6};
}

done_testing();
