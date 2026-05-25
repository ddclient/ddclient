use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }

# --run-once should default to false
{
    local %ddclient::opt;
    local %ddclient::globals;
    local %ddclient::config;
    is(ddclient::opt('run-once'), 0, 'run-once defaults to false');
}

# --run-once overrides daemon even when daemon is set in globals (config file)
{
    local %ddclient::opt;
    local %ddclient::globals;
    local %ddclient::config;
    $ddclient::globals{daemon} = ddclient::interval('5m');
    $ddclient::globals{'run-once'} = 1;

    my $daemon = ddclient::opt('daemon');
    $daemon = undef if ddclient::opt('run-once');

    is($daemon, undef, '--run-once forces daemon to undef when daemon set in config');
    is(ddclient::opt('daemon'), ddclient::interval('5m'), 'opt(daemon) itself is unchanged');
}

# --run-once has no effect when daemon is already unset
{
    local %ddclient::opt;
    local %ddclient::globals;
    local %ddclient::config;
    $ddclient::globals{'run-once'} = 1;

    my $daemon = ddclient::opt('daemon');
    $daemon = undef if ddclient::opt('run-once');

    is($daemon, undef, '--run-once with no daemon set leaves daemon undef');
}

# daemon without --run-once is left as-is
{
    local %ddclient::opt;
    local %ddclient::globals;
    local %ddclient::config;
    $ddclient::globals{daemon} = ddclient::interval('5m');

    my $daemon = ddclient::opt('daemon');
    $daemon = undef if ddclient::opt('run-once');

    is($daemon, ddclient::interval('5m'), 'daemon is preserved when run-once is not set');
}

done_testing();
