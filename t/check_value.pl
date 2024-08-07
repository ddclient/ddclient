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
        want  => undef,
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
        want  => undef,
    },
    {
        type  => ddclient::T_URL(),
        input => 'bad-url',
        want  => undef,
    },
);
for my $tc (@test_cases) {
    my $got = ddclient::check_value($tc->{input}, ddclient::setv($tc->{type}, 0, 0, undef, undef));
    is($got, $tc->{want}, "$tc->{type}: $tc->{input}");
}
done_testing();
