use Test::More;
use strict;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my @test_cases = (
    {
        type  => ddclient::T_FQDN(),
        input => 'example.com',
        want  => 'example.com',
    },
    {
        type  => ddclient::T_FQDN(),
        input => 'example',
        want_invalid => 1,
    },
    {
        type  => ddclient::T_URL(),
        input => 'https://www.example.com',
        want  => 'https://www.example.com',
    },
    {
        type  => ddclient::T_URL(),
        input => 'https://directnic.com/dns/gateway/ad133/',
        want  => 'https://directnic.com/dns/gateway/ad133/',
    },
    {
        type  => ddclient::T_URL(),
        input => 'HTTPS://MixedCase.com/',
        want  => 'HTTPS://MixedCase.com/',
    },
    {
        type  => ddclient::T_URL(),
        input => 'ftp://bad.protocol/',
        want_invalid => 1,
    },
    {
        type  => ddclient::T_URL(),
        input => 'bad-url',
        want_invalid => 1,
    },
);
for my $tc (@test_cases) {
    my $got;
    my $got_invalid = !(eval {
        $got = ddclient::check_value($tc->{input},
                                     ddclient::setv($tc->{type}, 0, 0, undef, undef));
        1;
    });
    is($got_invalid, !!$tc->{want_invalid}, "$tc->{type}: $tc->{input}: validity");
    is($got, $tc->{want}, "$tc->{type}: $tc->{input}: normalization") if !$tc->{want_invalid};
}
done_testing();
