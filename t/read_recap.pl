use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
use File::Temp;
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;
local %ddclient::protocols = (
    protocol_a => ddclient::Protocol->new(
        recapvars => {
            host => ddclient::T_STRING(),
            var_a => ddclient::T_BOOL(),
        },
    ),
    protocol_b => ddclient::Protocol->new(
        recapvars => {
            host => ddclient::T_STRING(),
            var_b => ddclient::T_NUMBER(),
        },
        cfgvars => {
            var_b_non_recap => {type => ddclient::T_ANY()},
        },
    ),
);
local %ddclient::cfgvars = (merged => {map({ %{$ddclient::protocols{$_}{cfgvars} // {}}; }
                                           sort(keys(%ddclient::protocols)))});

my @test_cases = (
    {
        desc => "ok value",
        cachefile_lines => ["var_a=yes host_a"],
        want => {host_a => {host => 'host_a', var_a => 1}},
    },
    {
        desc => "unknown host",
        cachefile_lines => ["var_a=yes host_c"],
        want => {},
    },
    {
        desc => "unknown var",
        cachefile_lines => ["var_b=123 host_a"],
        want => {host_a => {host => 'host_a'}},
    },
    {
        desc => "invalid value",
        cachefile_lines => ["var_a=wat host_a"],
        want => {host_a => {host => 'host_a'}},
    },
    {
        desc => "multiple entries",
        cachefile_lines => [
            "var_a=yes host_a",
            "var_b=123 host_b",
        ],
        want => {
            host_a => {host => 'host_a', var_a => 1},
            host_b => {host => 'host_b', var_b => 123},
        },
    },
    {
        desc => "non-recap vars are not loaded to %recap",
        cachefile_lines => ["var_b_non_recap=foo host_b"],
        want => {host_b => {host => 'host_b'}},
    },
    {
        desc => "non-recap vars are scrubbed from %recap",
        cachefile_lines => ["var_b_non_recap=foo host_b"],
        recap => {host_b => {host => 'host_b', var_b_non_recap => 'foo'}},
        want => {host_b => {host => 'host_b'}},
    },
    {
        desc => "unknown hosts are scrubbed from %recap",
        cachefile_lines => ["host_a", "host_c"],
        recap => {host_a => {host => 'host_a'}, host_c => {host => 'host_c'}},
        want => {host_a => {host => 'host_a'}},
    },
);

for my $tc (@test_cases) {
    my $cachef = File::Temp->new();
    print($cachef join('', map("$_\n", "## $ddclient::program-$ddclient::version",
                               @{$tc->{cachefile_lines}})));
    $cachef->close();
    local $ddclient::globals{cache} = "$cachef";
    local %ddclient::recap = %{$tc->{recap} // {}};
    my %want_config = (
        host_a => {protocol => 'protocol_a'},
        host_b => {protocol => 'protocol_b'},
    );
    # Deep clone %want_config so we can check for changes.
    local %ddclient::config;
    $ddclient::config{$_} = {%{$want_config{$_}}} for keys(%want_config);

    ddclient::read_recap($cachef->filename());

    TODO: {
        local $TODO = $tc->{want_TODO};
        is_deeply(\%ddclient::recap, $tc->{want}, "$tc->{desc}: %recap")
            or diag(ddclient::repr(Values => [\%ddclient::recap, $tc->{want}],
                                   Names => ['*got', '*want']));
    }
    is_deeply(\%ddclient::config, \%want_config, "$tc->{desc}: %config")
        or diag(ddclient::repr(Values => [\%ddclient::config, \%want_config],
                               Names => ['*got', '*want']));
}

done_testing();
