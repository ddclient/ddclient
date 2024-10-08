use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t;

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

subtest "Get default interface and IP for test system (IPv4)" => sub {
    my $interface = ddclient::get_default_interface(4);
    plan(skip_all => 'no IPv4 interface') if !$interface;
    isnt($interface, "lo", "Check for loopback 'lo'");
    isnt($interface, "lo0", "Check for loopback 'lo0'");
    my $ip1 = ddclient::get_ip_from_interface("default", 4);
    my $ip2 = ddclient::get_ip_from_interface($interface, 4);
    is($ip1, $ip2, "Check IPv4 from default interface");
    SKIP: {
        skip('default interface does not have an appropriate IPv4 addresses') if !$ip1;
        ok(ddclient::is_ipv4($ip1), "Valid IPv4 from get_ip_from_interface($interface)");
    }
};

subtest "Get default interface and IP for test system (IPv6)" => sub {
    my $interface = ddclient::get_default_interface(6);
    plan(skip_all => 'no IPv6 interface') if !$interface;
    isnt($interface, "lo", "Check for loopback 'lo'");
    isnt($interface, "lo0", "Check for loopback 'lo0'");
    my $ip1 = ddclient::get_ip_from_interface("default", 6);
    my $ip2 = ddclient::get_ip_from_interface($interface, 6);
    is($ip1, $ip2, "Check IPv6 from default interface");
    SKIP: {
        skip('default interface does not have an appropriate IPv6 addresses') if !$ip1;
        ok(ddclient::is_ipv6($ip1), "Valid IPv6 from get_ip_from_interface($interface)");
    }
};

done_testing();
