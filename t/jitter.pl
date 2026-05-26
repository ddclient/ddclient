use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

my @sleep_calls;
my @rand_args;
my @rand_returns;
my $sleep_duration;
my $config_file;

{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    chmod 0600, $path;
    $config_file = $path;
}

BEGIN {
    no warnings 'redefine';

    *CORE::GLOBAL::rand = sub {
        my ($limit) = @_;
        push @rand_args, $limit;
        return @rand_returns ? shift(@rand_returns) : 0;
    };

    *CORE::GLOBAL::sleep = sub {
        my ($delay) = @_;
        push @sleep_calls, $delay;
        if (!defined $sleep_duration && $0 =~ /sleeping for\s+(\d+)\s+seconds/) {
            $sleep_duration = $1;
        }
        die "__TEST_CAPTURED_SLEEP__\n";
    };
}

eval { require 'ddclient'; } or BAIL_OUT($@);

my $daemon_entry =
       ddclient->can('main')
    || ddclient->can('run')
    || ddclient->can('daemon')
    || BAIL_OUT('Unable to find a callable ddclient daemon entry point');

sub capture_daemon_sleep_once {
    my (%args) = @_;

    @sleep_calls  = ();
    @rand_args    = ();
    @rand_returns = ($args{rand_return});
    $sleep_duration = undef;

    my $ok = eval {
        local @ARGV = (
            '--foreground',
            "--file=$config_file",
            "--daemon=$args{daemon}",
            "--jitter=$args{jitter}",
        );
        $daemon_entry->();
        1;
    };

    like($@, qr/__TEST_CAPTURED_SLEEP__/, 'daemon loop reached sleep and was intercepted')
        unless $ok;

    return defined $sleep_duration ? $sleep_duration : $sleep_calls[0];
}

# Exercise the real daemon-path jitter handling: rand() is called with the
# configured jitter, and the resulting delay remains an integer within the
# expected [daemon, daemon + jitter) range.
{
    my $daemon = 300;
    my $jitter = 60;
    my $delay = capture_daemon_sleep_once(
        daemon      => $daemon,
        jitter      => $jitter,
        rand_return => 17,
    );

    is(scalar @rand_args, 1, 'rand called exactly once when jitter is non-zero');
    is($rand_args[0], $jitter, 'rand called with configured jitter');
    cmp_ok($delay, '>=', $daemon, 'sleep delay is at least daemon interval');
    cmp_ok($delay, '<', $daemon + $jitter, 'sleep delay is less than daemon + jitter');
    is($delay, int($delay), 'sleep delay remains an integer');
}

# Zero jitter should not extend the daemon interval.
{
    my $daemon = 300;
    my $jitter = 0;
    my $delay = capture_daemon_sleep_once(
        daemon      => $daemon,
        jitter      => $jitter,
        rand_return => 0,
    );

    is(scalar @rand_args, 0, 'rand not called when jitter is 0');
    is($delay, $daemon, 'sleep delay matches daemon interval when jitter is 0');
}

done_testing();
