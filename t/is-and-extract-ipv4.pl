use Test::More;
use B qw(perlstring);

SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);


my @valid_ipv4 = (
    "192.168.1.1",
    "0.0.0.0",
    "000.000.000.000",
    "255.255.255.255",
    "10.0.0.0",
);

my @invalid_ipv4 = (
    undef,
    "",
    "192.168.1",
    "0.0.0",
    "000.000",
    "256.256.256.256",
    ".10.0.0.0",
);


subtest "is_ipv4() with valid addresses" => sub {
    foreach my $ip (@valid_ipv4) {
        ok(ddclient::is_ipv4($ip), "is_ipv4('$ip')");
    }
};

subtest "is_ipv4() with invalid addresses" => sub {
    foreach my $ip (@invalid_ipv4) {
        ok(!ddclient::is_ipv4($ip), sprintf("!is_ipv4(%s)", defined($ip) ? "'$ip'" : 'undef'));
    }
};

subtest "is_ipv4() with char adjacent to valid address" => sub {
    foreach my $ch (split(//, '/.,:z @$#&%!^*()_-+'), "\n") {
        subtest perlstring($ch) => sub {
            foreach my $ip (@valid_ipv4) {
                subtest $ip => sub {
                    my $test = $ch . $ip;  # insert at front
                    ok(!ddclient::is_ipv4($test), "!is_ipv4('$test')");
                    $test = $ip . $ch;  # add at end
                    ok(!ddclient::is_ipv4($test), "!is_ipv4('$test')");
                    $test = $ch . $ip . $ch; # wrap front and end
                    ok(!ddclient::is_ipv4($test), "!is_ipv4('$test')");
                };
            }
        };
    }
};

subtest "extract_ipv4()" => sub {
    my @test_cases = (
        {name => "undef",     text => undef,              want => undef},
        {name => "empty",     text => "",                 want => undef},
        {name => "invalid",   text => "1.2.3.256",        want => undef},
        {name => "two addrs", text => "1.1.1.1\n2.2.2.2", want => "1.1.1.1"},
        {name => "host+port", text => "1.2.3.4:123",      want => "1.2.3.4"},
        {name => "zero pad",  text => "001.002.003.004",  want => "1.2.3.4"},
    );
    foreach my $tc (@test_cases) {
        is(ddclient::extract_ipv4($tc->{text}), $tc->{want}, $tc->{name});
    }
};

subtest "extract_ipv4() of valid addr with adjacent non-word char" => sub {
    foreach my $wb (split(//, '/, @$#&%!^*()_-+:'), "\n") {
        subtest perlstring($wb) => sub {
            my $test = "";
            foreach my $ip (@valid_ipv4) {
                $test = "foo" . $wb . $ip . $wb . "bar"; # wrap front and end
                $ip =~ s/\b0+\B//g; ## remove embedded leading zeros for testing
                is(ddclient::extract_ipv4($test), $ip, perlstring($test));
            }
        };
    }
};

done_testing();
