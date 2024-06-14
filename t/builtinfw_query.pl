use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }

sub setbuiltinfw {
    my ($fw) = @_;
    no warnings 'once';
    $ddclient::builtinfw{$fw->{name}} = $fw;
    %ddclient::ip_strategies = ddclient::builtinfw_strategy($fw->{name});
    %ddclient::ipv4_strategies = ddclient::builtinfwv4_strategy($fw->{name});
    %ddclient::ipv6_strategies = ddclient::builtinfwv6_strategy($fw->{name});
}

my @gotcalls;

my $skip_test_fw = 't/builtinfw_query.pl skip test';
setbuiltinfw({
    name => $skip_test_fw,
    query => sub { return '192.0.2.1 skip1 192.0.2.2 skip2 192.0.2.3'; },
    queryv4 => sub { return '192.0.2.4 skip1 192.0.2.5 skip3 192.0.2.6'; },
    queryv6 => sub { return '2001:db8::1 skip1 2001:db8::2 skip4 2001:db8::3'; },
});

my @skip_test_cases = (
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

for my $tc (@skip_test_cases) {
    my $h = "t/builtinfw_query.pl $tc->{desc}";
    $ddclient::config{$h} = {
        $tc->{useopt} => $skip_test_fw,
        'fw-skip' => 'skip1',
        %{$tc->{cfgxtra}},
    };
    my $got = $tc->{getip}(ddclient::strategy_inputs($tc->{useopt}, $h));
    is($got, $tc->{want}, $tc->{desc});
}

my $default_inputs_fw = 't/builtinfw_query.pl default inputs';
setbuiltinfw({
    name => $default_inputs_fw,
    query => sub { my %p = @_; push(@gotcalls, \%p); return '192.0.2.1'; },
    queryv4 => sub { my %p = @_; push(@gotcalls, \%p); return '192.0.2.2'; },
    queryv6 => sub { my %p = @_; push(@gotcalls, \%p); return '2001:db8::1'; },
});
my @default_inputs_test_cases = (
    {
        desc => 'use with default inputs',
        getip => \&ddclient::get_ip,
        useopt => 'use',
        want => {use => $default_inputs_fw, fw => 'server', 'fw-skip' => 'skip',
                 'fw-login' => 'login', 'fw-password' => 'password', 'fw-ssl-validate' => 1},
    },
    {
        desc => 'usev4 with default inputs',
        getip => \&ddclient::get_ipv4,
        useopt => 'usev4',
        want => {usev4 => $default_inputs_fw, fwv4 => 'serverv4', fw => 'server',
                 'fwv4-skip' => 'skipv4', 'fw-skip' => 'skip', 'fw-login' => 'login',
                 'fw-password' => 'password', 'fw-ssl-validate' => 1},
    },
    {
        desc => 'usev6 with default inputs',
        getip => \&ddclient::get_ipv6,
        useopt => 'usev6',
        want => {usev6 => $default_inputs_fw, fwv6 => 'serverv6', 'fwv6-skip' => 'skipv6'},
    },
);
for my $tc (@default_inputs_test_cases) {
    my $h = "t/builtinfw_query.pl $tc->{desc}";
    $ddclient::config{$h} = {
        $tc->{useopt} => $default_inputs_fw,
        'fw' => 'server',
        'fwv4' => 'serverv4',
        'fwv6' => 'serverv6',
        'fw-login' => 'login',
        'fw-password' => 'password',
        'fw-ssl-validate' => 1,
        'fw-skip' => 'skip',
        'fwv4-skip' => 'skipv4',
        'fwv6-skip' => 'skipv6',
    };
    @gotcalls = ();
    $tc->{getip}(ddclient::strategy_inputs($tc->{useopt}, $h));
    is_deeply(\@gotcalls, [$tc->{want}], $tc->{desc});
}

my $custom_inputs_fw = 't/builtinfw_query.pl custom inputs';
setbuiltinfw({
    name => $custom_inputs_fw,
    query => sub { my %p = @_; push(@gotcalls, \%p); return '192.0.2.1'; },
    inputs => ['if'],
    queryv4 => sub { my %p = @_; push(@gotcalls, \%p); return '192.0.2.2'; },
    inputsv4 => ['ifv4'],
    queryv6 => sub { my %p = @_; push(@gotcalls, \%p); return '2001:db8::1'; },
    inputsv6 => ['ifv6'],
});

my @custom_inputs_test_cases = (
    {
        desc => 'use with custom inputs',
        getip => \&ddclient::get_ip,
        useopt => 'use',
        want => {use => $custom_inputs_fw, if => 'eth0'},
    },
    {
        desc => 'usev4 with custom inputs',
        getip => \&ddclient::get_ipv4,
        useopt => 'usev4',
        want => {usev4 => $custom_inputs_fw, ifv4 => 'eth4'},
    },
    {
        desc => 'usev6 with custom inputs',
        getip => \&ddclient::get_ipv6,
        useopt => 'usev6',
        want => {usev6 => $custom_inputs_fw, ifv6 => 'eth6'},
    },
);

for my $tc (@custom_inputs_test_cases) {
    my $h = "t/builtinfw_query.pl $tc->{desc}";
    $ddclient::config{$h} = {
        $tc->{useopt} => $custom_inputs_fw,
        'if' => 'eth0',
        'ifv4' => 'eth4',
        'ifv6' => 'eth6',
    };
    @gotcalls = ();
    $tc->{getip}(ddclient::strategy_inputs($tc->{useopt}, $h));
    is_deeply(\@gotcalls, [$tc->{want}], $tc->{desc});
}

done_testing();
