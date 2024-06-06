use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
my $have_mock = eval { require Test::MockModule; };

my $failmsg;
my $module;
if ($have_mock) {
    $module = Test::MockModule->new('ddclient');
    # Note: 'mock' is used instead of 'redefine' because 'redefine' is not available in the versions
    # of Test::MockModule distributed with old Debian and Ubuntu releases.
    $module->mock('failed', sub { $failmsg //= ''; $failmsg .= sprintf(shift, @_) . "\n"; });
}

my @test_cases = (
    {
        desc => 'malformed not OK',
        input => 'malformed',
        want => 0,
        wantmsg => qr/unexpected/,
    },
    {
        desc => 'HTTP/1.1 200 OK',
        input => 'HTTP/1.1 200 OK',
        want => 1,
    },
    {
        desc => 'HTTP/2 200 OK',
        input => 'HTTP/2 200 OK',
        want => 1,
    },
    {
        desc => 'HTTP/3 200 OK',
        input => 'HTTP/3 200 OK',
        want => 1,
    },
    {
        desc => '401 not OK, fallback message',
        input => 'HTTP/1.1 401 ',
        want => 0,
        wantmsg => qr/authentication failed/,
    },
    {
        desc => '403 not OK, fallback message',
        input => 'HTTP/1.1 403 ',
        want => 0,
        wantmsg => qr/not authorized/,
    },
    {
        desc => 'other 4xx not OK',
        input => 'HTTP/1.1 456 bad',
        want => 0,
        wantmsg => qr/bad/,
    },
    {
        desc => 'only first line is logged on error',
        input => "HTTP/1.1 404 not found\n\nbody",
        want => 0,
        wantmsg => qr/(?!body)/,
    },
);

for my $tc (@test_cases) {
    subtest $tc->{desc} => sub {
        $failmsg = '';
        is(ddclient::header_ok('host', $tc->{input}), $tc->{want}, 'return value matches');
        SKIP: {
            skip('Test::MockModule not available') if !$have_mock;
            like($failmsg, $tc->{wantmsg} // qr/^$/, 'fail message matches');
        }
    };
}

done_testing();
