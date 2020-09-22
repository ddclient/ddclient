use Test::More;
use ddclient::t;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

# To aid in debugging, uncomment the following lines. (They are normally left commented to avoid
# accidentally interfering with the Test Anything Protocol messages written by Test::More.)
#STDOUT->autoflush(1);
#$ddclient::globals{'debug'} = 1;

subtest "get_default_interface tests" => sub {
    for my $sample (@ddclient::t::routing_samples) {
        if (defined($sample->{want_ipv4_if})) {
            my $interface = ddclient::get_default_interface(4, $sample->{text});
            is($interface, $sample->{want_ipv4_if}, $sample->{name});
        }
        if (defined($sample->{want_ipv6_if})) {
            my $interface = ddclient::get_default_interface(6, $sample->{text});
            is($interface, $sample->{want_ipv6_if}, $sample->{name});
        }
    }
};

subtest "get_ip_from_interface tests" => sub {
    for my $sample (@ddclient::t::interface_samples) {
        # interface name is undef as we are passing in test data
        if (defined($sample->{want_ipv4_from_if})) {
            my $ip = ddclient::get_ip_from_interface(undef, 4, undef, $sample->{text}, $sample->{MacOS});
            is($ip, $sample->{want_ipv4_from_if}, $sample->{name});
        }
        if (defined($sample->{want_ipv6gua_from_if})) {
            my $ip = ddclient::get_ip_from_interface(undef, 6, 'gua', $sample->{text}, $sample->{MacOS});
            is($ip, $sample->{want_ipv6gua_from_if}, $sample->{name});
        }
        if (defined($sample->{want_ipv6ula_from_if})) {
            my $ip = ddclient::get_ip_from_interface(undef, 6, 'ula', $sample->{text}, $sample->{MacOS});
            is($ip, $sample->{want_ipv6ula_from_if}, $sample->{name});
        }
    }
};

subtest "Get default interface and IP for test system" => sub {
    my $interface = ddclient::get_default_interface(4);
    if ($interface) {
        isnt($interface, "lo", "Check for loopback 'lo'");
        isnt($interface, "lo0", "Check for loopback 'lo0'");
        my $ip1 = ddclient::get_ip_from_interface("default", 4);
        my $ip2 = ddclient::get_ip_from_interface($interface, 4);
        is($ip1, $ip2, "Check IPv4 from default interface");
        ok(ddclient::is_ipv4($ip1), "Valid IPv4 from get_ip_from_interface($interface)");
    }
    $interface = ddclient::get_default_interface(6);
    if ($interface) {
        isnt($interface, "lo", "Check for loopback 'lo'");
        isnt($interface, "lo0", "Check for loopback 'lo0'");
        my $ip1 = ddclient::get_ip_from_interface("default", 6);
        my $ip2 = ddclient::get_ip_from_interface($interface, 6);
        is($ip1, $ip2, "Check IPv6 from default interface");
        ok(ddclient::is_ipv6($ip1), "Valid IPv6 from get_ip_from_interface($interface)");
    }
};

done_testing();
