use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $h = 't/interval_expired.pl';

my $default_now = 1000000000;

my @test_cases = (
    {
        interval => 'inf',
        want => 0,
    },
    {
        now => 'inf',
        interval => 'inf',
        want => 0,
    },
    {
        cache => '-inf',
        interval => 'inf',
        want => 0,
    },
    {
        cache => undef,  # Falsy cache value.
        interval => 'inf',
        want => 0,
    },
    {
        now => 0,
        cache => 0,  # Different kind of falsy cache value.
        interval => 'inf',
        want => 0,
    },
);

for my $tc (@test_cases) {
    $tc->{now} //= $default_now;
    # For convenience, $tc->{cache} is an offset from $tc->{now}, not an absolute time..
    my $cachetime = $tc->{now} + $tc->{cache} if defined($tc->{cache});
    $ddclient::config{$h} = {'interval' => $tc->{interval}};
    %ddclient::config if 0;  # suppress spurious warning "Name used only once: possible typo"
    $ddclient::cache{$h} = {'cached-time' => $cachetime} if defined($cachetime);
    %ddclient::cache if 0;  # suppress spurious warning "Name used only once: possible typo"
    $ddclient::now = $tc->{now};
    $ddclient::now if 0; # suppress spurious warning "Name used only once: possible typo"
    my $desc = "now=$tc->{now}, cache=${\($cachetime // 'undef')}, interval=$tc->{interval}";
    is(ddclient::interval_expired($h, 'cached-time', 'interval'), $tc->{want}, $desc);
}

done_testing();
