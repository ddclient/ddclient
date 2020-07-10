use Test::More;
use File::Spec::Functions;
use File::Temp;
eval { require Test::MockModule; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $warning;

my $module = Test::MockModule->new('ddclient');
# Note: 'mock' is used instead of 'redefine' because 'redefine' is not available in the versions of
# Test::MockModule distributed with old Debian and Ubuntu releases.
$module->mock('warning', sub {
    BAIL_OUT("warning already logged") if defined($warning);
    $warning = sprintf(shift, @_);
});
my $tmpdir = File::Temp->newdir();
my $dir = $tmpdir->dirname();
diag("temporary directory: $dir");

sub tc {
    return {
        name => shift,
        f => shift,
        warning_regex => shift,
    };
}

my @test_cases = (
    tc("create cache file",    catfile($dir, 'a', 'b', 'cachefile'),        undef),
    tc("overwrite cache file", catfile($dir, 'a', 'b', 'cachefile'),        undef),
    tc("bad directory",        catfile($dir, 'a', 'b', 'cachefile', 'bad'), qr/Failed to create/i),
    tc("bad file",             catfile($dir, 'a', 'b'),                     qr/Failed to create/i),
);

for my $tc (@test_cases) {
    $warning = undef;
    ddclient::write_cache($tc->{f});
    subtest $tc->{name} => sub {
        if (defined($tc->{warning_regex})) {
            like($warning, $tc->{warning_regex}, "expected warning message");
        } else {
            ok(!defined($warning), "no warning");
            ok(-f $tc->{f}, "cache file exists");
        }
    };
}

done_testing();
