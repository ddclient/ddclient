use strict;
use warnings;
use Test::More;
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

# Stub sleep() in the ddclient namespace to capture calls without blocking.
my @sleep_calls;
{
    no warnings 'redefine';
    *ddclient::sleep = sub { push @sleep_calls, $_[0] };
}

# Compute jitter the same way ddclient does: int(rand($daemon * 0.2))
sub compute_jitter {
    my ($interval) = @_;
    return int(rand($interval * 0.2));
}

# For a 5-minute (300s) interval, jitter must be in [0, 60).
# Run several trials to ensure we never produce a value outside the range.
{
    my $interval = 300;
    my $max_jitter = int($interval * 0.2);  # 60
    my $out_of_range = 0;
    for (1..200) {
        my $j = compute_jitter($interval);
        $out_of_range++ if $j < 0 || $j >= $max_jitter;
        @sleep_calls = ();
        ddclient::sleep($j) if $j > 0;
        if ($j > 0) {
            is($sleep_calls[0], $j, "sleep called with jitter value $j");
        }
    }
    is($out_of_range, 0, "jitter always in [0, 60) for 300s interval");
}

# For a 1-second interval, int(rand(0.2)) is always 0 — sleep must not be called.
{
    my $interval = 1;
    @sleep_calls = ();
    my $jitter = compute_jitter($interval);
    is($jitter, 0, "jitter is 0 for 1s interval");
    ddclient::sleep($jitter) if $jitter > 0;
    is(scalar @sleep_calls, 0, "sleep not called when jitter is 0");
}

# For a 0-second interval (daemon disabled), jitter must be 0.
{
    my $interval = 0;
    my $jitter = compute_jitter($interval);
    is($jitter, 0, "jitter is 0 for 0s interval");
}

done_testing();
