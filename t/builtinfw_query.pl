use Test::More;
eval { require Test::MockModule; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $debug_msg;
my $module = Test::MockModule->new('ddclient');
# Note: 'mock' is used instead of 'redefine' because 'redefine' is not available in the versions of
# Test::MockModule distributed with old Debian and Ubuntu releases.
$module->mock('debug', sub {
    BAIL_OUT("debug already called") if defined($debug_msg);
    $debug_msg = sprintf(shift, @_);
});
my $got_host;
$ddclient::builtinfw{dummy_device} = {
    name => 'dummy device for testing',
    query => sub { ($got_host) = @_; return ("asdf", "192.0.2.5 foo 192.0.2.123 bar"); },
};
$ddclient::globals{'fw-skip'} = 'foo';

my $got = ddclient::get_ip('dummy_device', 'dummy_host');

is($got_host, 'dummy_host', "host is passed through");
is($got, '192.0.2.123', "returned IP matches");
like($debug_msg, qr/\basdf\b/, "returned arg is properly handled");

done_testing();
