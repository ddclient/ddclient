use Test::More;
use File::Temp;
use Scalar::Util qw(refaddr);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;
local %ddclient::protocols = (
    protocol_a => {
        variables => {
            'host' => {type => ddclient::T_STRING(), recap => 1},
            'mtime' => {type => ddclient::T_NUMBER(), recap => 1},
            'atime' => {type => ddclient::T_NUMBER(), recap => 1},
            'wtime' => {type => ddclient::T_NUMBER(), recap => 1},
            'ip' => {type => ddclient::T_IP(), recap => 1},
            'ipv4' => {type => ddclient::T_IPV4(), recap => 1},
            'ipv6' => {type => ddclient::T_IPV6(), recap => 1},
            'status' => {type => ddclient::T_ANY(), recap => 1},
            'status-ipv4' => {type => ddclient::T_ANY(), recap => 1},
            'status-ipv6' => {type => ddclient::T_ANY(), recap => 1},
            'warned-min-error-interval' => {type => ddclient::T_ANY(), recap => 1},
            'warned-min-interval' => {type => ddclient::T_ANY(), recap => 1},

            'var_a' => {type => ddclient::T_BOOL(), recap => 1},
        },
    },
    protocol_b => {
        variables => {
            'host' => {type => ddclient::T_STRING(), recap => 1},
            'mtime' => {type => ddclient::T_NUMBER()},  # Intentionally not a recap var.
            'var_b' => {type => ddclient::T_NUMBER(), recap => 1},
        },
    },
);
local %ddclient::variables =
    (merged => {map({ %{$ddclient::protocols{$_}{variables}}; } sort(keys(%ddclient::protocols)))});

# Sentinel value that means "this hash entry should be deleted."
my $DOES_NOT_EXIST = [];

my @test_cases = (
    {
        desc => "ok value",
        cachefile_lines => ["var_a=yes host_a"],
        want => {host_a => {host => 'host_a', var_a => 1}},
        # No config changes are expected because `var_a` is not a "status" recap var.
    },
    {
        desc => "unknown host",
        cachefile_lines => ["var_a=yes host_c"],
        want => {},
        want_TODO => "longstanding minor issue, doesn't affect functionality",
    },
    {
        desc => "unknown var",
        cachefile_lines => ["var_b=123 host_a"],
        want => {host_a => {host => 'host_a'}},
        want_TODO => "longstanding minor issue, doesn't affect functionality",
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
        # No config changes are expected because `var_a` and `var_b` are not "status" recap vars.
    },
    {
        desc => "used to be status vars",
        cachefile_lines => ["ip=192.0.2.1,status=good host_a"],
        want => {host_a => {host => 'host_a', ip => '192.0.2.1', status => 'good'}},
        # No config changes are expected because `ip` and `status` are no longer "status" recap
        # vars.
    },
    {
        desc => "status vars",
        cachefile_lines => ["mtime=1234567890,atime=1234567891,wtime=1234567892,ipv4=192.0.2.1,ipv6=2001:db8::1,status-ipv4=good,status-ipv6=bad,warned-min-interval=1234567893,warned-min-error-interval=1234567894 host_a"],
        want => {host_a => {
            'host' => 'host_a',
            'mtime' => 1234567890,
            'atime' => 1234567891,
            'wtime' => 1234567892,
            'ipv4' => '192.0.2.1',
            'ipv6' => '2001:db8::1',
            'status-ipv4' => 'good',
            'status-ipv6' => 'bad',
            'warned-min-interval' => 1234567893,
            'warned-min-error-interval' => 1234567894,
        }},
        want_config_changes => {host_a => {
            'mtime' => 1234567890,
            'atime' => 1234567891,
            'wtime' => 1234567892,
            'ipv4' => '192.0.2.1',
            'ipv6' => '2001:db8::1',
            'status-ipv4' => 'good',
            'status-ipv6' => 'bad',
            'warned-min-interval' => 1234567893,
            'warned-min-error-interval' => 1234567894,
        }},
    },
    {
        desc => "unset status var clears config",
        cachefile_lines => ["host_a"],
        config => {host_a => {
            'mtime' => 1234567890,
            'atime' => 1234567891,
            'wtime' => 1234567892,
            'ipv4' => '192.0.2.1',
            'ipv6' => '2001:db8::1',
            'status-ipv4' => 'good',
            'status-ipv6' => 'bad',
            'warned-min-interval' => 1234567893,
            'warned-min-error-interval' => 1234567894,
            'var_a' => 1,
        }},
        want => {host_a => {host => 'host_a'}},
        want_config_changes => {host_a => {
            'mtime' => $DOES_NOT_EXIST,
            'atime' => $DOES_NOT_EXIST,
            'wtime' => $DOES_NOT_EXIST,
            'ipv4' => $DOES_NOT_EXIST,
            'ipv6' => $DOES_NOT_EXIST,
            'status-ipv4' => $DOES_NOT_EXIST,
            'status-ipv6' => $DOES_NOT_EXIST,
            'warned-min-interval' => $DOES_NOT_EXIST,
            'warned-min-error-interval' => $DOES_NOT_EXIST,
            # `var_a` should remain untouched.
        }},
    },
    {
        desc => "non-recap vars are not loaded to %recap or copied to %config",
        cachefile_lines => ["mtime=1234567890 host_b"],
        want => {host_b => {host => 'host_b'}},
        want_TODO => "longstanding minor issue, doesn't affect functionality",
    },
    {
        desc => "non-recap vars are scrubbed from %recap",
        cachefile_lines => ["mtime=1234567890 host_b"],
        recap => {host_b => {host => 'host_b', mtime => 1234567891}},
        want => {host_b => {host => 'host_b'}},
        want_TODO => "longstanding minor issue, doesn't affect functionality",
    },
    {
        desc => "unknown hosts are scrubbed from %recap",
        cachefile_lines => ["host_a", "host_c"],
        recap => {host_a => {host => 'host_a'}, host_c => {host => 'host_c'}},
        want => {host_a => {host => 'host_a'}},
        want_TODO => "longstanding minor issue, doesn't affect functionality",
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
    $tc->{config} //= {};
    $want_config{$_} = {%{$want_config{$_} // {}}, %{$tc->{config}{$_}}} for keys(%{$tc->{config}});
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
    TODO: {
        local $TODO = $tc->{want_config_changes_TODO};
        $tc->{want_config_changes} //= {};
        $want_config{$_} = {%{$want_config{$_} // {}}, %{$tc->{want_config_changes}{$_}}}
            for keys(%{$tc->{want_config_changes}});
        for my $h (keys(%want_config)) {
            for my $k (keys(%{$want_config{$h}})) {
                my $a = refaddr($want_config{$h}{$k});
                delete($want_config{$h}{$k}) if defined($a) && $a == refaddr($DOES_NOT_EXIST);
            }
        }
        is_deeply(\%ddclient::config, \%want_config, "$tc->{desc}: %config")
            or diag(ddclient::repr(Values => [\%ddclient::config, \%want_config],
                                   Names => ['*got', '*want']));
    }
}

done_testing();
