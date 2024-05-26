use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

# Fake curl.  Use the printf utility, which can process escapes.  This allows Perl to drive the fake
# curl with plain ASCII and get arbitrary bytes back, avoiding problems caused by any encoding that
# might be done by Perl (e.g., "use open ':encoding(UTF-8)';").
my @fakecurl = ('sh', '-c', 'printf %b "$1"', '--');

my @test_cases = (
    {
        desc => 'binary body',
        # Body is UTF-8 encoded ✨ (U+2728 Sparkles) followed by a 0xff byte (invalid UTF-8).
        printf => join('\r\n', ('HTTP/1.1 200 OK', '', '\0342\0234\0250\0377')),
        # The raw bytes should come through as equally valued codepoints.  They must not be decoded.
        want => "HTTP/1.1 200 OK\n\n\xe2\x9c\xa8\xff",
    },
);

for my $tc (@test_cases) {
    @ddclient::curl = (@fakecurl, $tc->{printf});
    $ddclient::curl if 0;  # suppress spurious warning "Name used only once: possible typo"
    my $got = ddclient::geturl(url => 'http://ignored');
    is($got, $tc->{want}, $tc->{desc});
}

done_testing();
