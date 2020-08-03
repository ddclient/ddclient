use Test::More;
use ddclient::t;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

# To aid in debugging, uncomment the following lines. (They are normally left commented to avoid
# accidentally interfering with the Test Anything Protocol messages written by Test::More.)
#STDOUT->autoflush(1);
#$ddclient::globals{'debug'} = 1;

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

done_testing();
