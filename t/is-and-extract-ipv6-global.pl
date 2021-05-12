use Test::More;
use ddclient::t;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

subtest "is_ipv6_global() with valid but non-globally-routable addresses" => sub {
    foreach my $ip (
        # The entirety of ::/16 is assumed to never contain globally routable addresses
        "::",
        "::1",
        "0:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        # fc00::/7 unique local addresses (ULA)
        "fc00::",
        "fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        # fe80::/10 link-local unicast addresses
        "fe80::",
        "febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        # ff00::/8 multicast addresses
        "ff00::",
        "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
        # Case insensitivity of the negative lookahead
        "FF00::",
    ) {
        ok(!ddclient::is_ipv6_global($ip), "!is_ipv6_global('$ip')");
    }
};

subtest "is_ipv6_global() with valid, globally routable addresses" => sub {
    foreach my $ip (
        "1::",                                      # just after ::/16 assumed non-global block
        "fbff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",  # just before fc00::/7 ULA block
        "fe00::",                                   # just after  fc00::/7 ULA block
        "fe7f:ffff:ffff:ffff:ffff:ffff:ffff:ffff",  # just before fe80::/10 link-local block
        "fec0::",                                   # just after  fe80::/10 link-local block
        "feff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",  # just before ff00::/8 multicast block
    ) {
        ok(ddclient::is_ipv6_global($ip), "is_ipv6_global('$ip')");
    }
};

subtest "extract_ipv6_global()" => sub {
    my @test_cases = (
        {name => "undef",                    text => undef,            want => undef},
        {name => "empty",                    text => "",               want => undef},
        {name => "only non-global",          text => "foo fe80:: bar", want => undef},
        {name => "single global",            text => "foo 2000:: bar", want => "2000::"},
        {name => "multiple globals",         text => "2000:: 3000::",  want => "2000::"},
        {name => "global before non-global", text => "2000:: fe80::",  want => "2000::"},
        {name => "non-global before global", text => "fe80:: 2000::",  want => "2000::"},
        {name => "zero pad",                 text => "2001::0001",     want => "2001::1"},
    );
    foreach my $tc (@test_cases) {
        is(ddclient::extract_ipv6_global($tc->{text}), $tc->{want}, $tc->{name});
    }
};

subtest "interface config samples" => sub {
    for my $sample (@ddclient::t::interface_samples) {
        if (defined($sample->{want_extract_ipv6_global})) {
            my $got = ddclient::extract_ipv6_global($sample->{text});
            is($got, $sample->{want_extract_ipv6_global}, $sample->{name});
        }
    }
};

done_testing();
