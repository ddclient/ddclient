use Test::More;
eval { require Test::MockModule; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

my $debug_msg;
my $module = Test::MockModule->new('ddclient');
# Note: 'mock' is used instead of 'redefine' because 'redefine' is not available in the versions of
# Test::MockModule distributed with old Debian and Ubuntu releases.
$module->mock('debug', sub {
    my $msg = sprintf(shift, @_);
    return unless ($msg =~ qr/^get_ip(v[46])?:/);
    BAIL_OUT("debug already called") if defined($debug_msg);
    $debug_msg = $msg;
});
my $got_host;
my $builtinfw = 't/builtinfw_query.pl';
$ddclient::builtinfw{$builtinfw} = {
    name => 'dummy device for testing',
    query => sub {
        ($got_host) = @_;
        return ($got_host, "192.0.2.1 skip1 192.0.2.2 skip2 192.0.2.3");
    },
    queryv4 => sub {
        ($got_host) = @_;
        return ($got_host, "192.0.2.4 skip1 192.0.2.5 skip3 192.0.2.6");
    },
    queryv6 => sub {
        ($got_host) = @_;
        return ($got_host, "2001:db8::1 skip1 2001:db8::2 skip4 2001:db8::3");
    },
};
%ddclient::builtinfw if 0;  # suppress spurious warning "Name used only once: possible typo"

my @test_cases = (
    {
        desc => 'query',
        getip => \&ddclient::get_ip,
        useopt => 'use',
        cfgxtra => {},
        want => '192.0.2.2',
    },
    {
        desc => 'queryv4',
        getip => \&ddclient::get_ipv4,
        useopt => 'usev4',
        cfgxtra => {'fwv4-skip' => 'skip3'},
        want => '192.0.2.6',
    },
    {
        desc => 'queryv4 with fw-skip fallback',
        getip => \&ddclient::get_ipv4,
        useopt => 'usev4',
        cfgxtra => {},
        want => '192.0.2.5',
    },
    {
        desc => 'queryv6',
        getip => \&ddclient::get_ipv6,
        useopt => 'usev6',
        cfgxtra => {'fwv6-skip' => 'skip4'},
        want => '2001:db8::3',
    },
    {
        # Support for --usev6=<builtin> wasn't added until after --fwv6-skip was added, so fallback
        # to the deprecated --fw-skip option was never needed.
        desc => 'queryv6 ignores fw-skip',
        getip => \&ddclient::get_ipv6,
        useopt => 'usev6',
        cfgxtra => {},
        want => '2001:db8::1',
    },
);

for my $tc (@test_cases) {
    subtest $tc->{desc} => sub {
        my $h = "t/builtinfw_query.pl $tc->{desc}";
        $ddclient::config{$h} = {
            $tc->{useopt} => $builtinfw,
            'fw-skip' => 'skip1',
            %{$tc->{cfgxtra}},
        };
        %ddclient::config if 0;  # suppress spurious warning "Name used only once: possible typo"
        undef($debug_msg);
        undef($got_host);
        my $got = $tc->{getip}($builtinfw, $h);
        is($got_host, $h, "host is passed through");
        is($got, $tc->{want}, "returned IP matches");
        like($debug_msg, qr/\b\Q$h\E\b/, "returned arg is properly handled");
    };
}

done_testing();
