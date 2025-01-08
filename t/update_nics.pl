use Test::More;
BEGIN { SKIP: { eval { require Test::Warnings; 1; } or skip($@, 1); } }
use File::Temp;
BEGIN { eval { require HTTP::Request; 1; } or plan(skip_all => $@); }
BEGIN { eval { require JSON::PP; 1; } or plan(skip_all => $@); JSON::PP->import(); }
use List::Util qw(max);
use Scalar::Util qw(refaddr);
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use ddclient::t::HTTPD;
use ddclient::t::ip;

httpd_required();

httpd('4')->run();
httpd('6')->run() if httpd('6');
local %ddclient::builtinweb = (
    v4 => {url => "" . httpd('4')->endpoint()},
    defined(httpd('6')) ? (v6 => {url => "" . httpd('6')->endpoint()}) : (),
);

# Sentinel value used by `mergecfg` that means "this hash entry should be deleted if it exists."
my $DOES_NOT_EXIST = [];

sub mergecfg {
    my %ret;
    for my $cfg (@_) {
        next if !defined($cfg);
        for my $h (keys(%$cfg)) {
            if (refaddr($cfg->{$h}) == refaddr($DOES_NOT_EXIST)) {
                delete($ret{$h});
                next;
            }
            $ret{$h} = {%{$ret{$h} // {}}, %{$cfg->{$h}}};
            for my $k (keys(%{$ret{$h}})) {
                my $a = refaddr($ret{$h}{$k});
                delete($ret{$h}{$k}) if defined($a) && $a == refaddr($DOES_NOT_EXIST);
            }
        }
    }
    return \%ret;
}

local $ddclient::globals{debug} = 1;
local $ddclient::globals{verbose} = 1;
local $ddclient::now = 1000;
our @updates;
local %ddclient::protocols = (
    # The `legacy` protocol reads the legacy `wantip` property and sets the legacy `ip` and `status`
    # properties.  (Modern protocol implementations read `wantipv4` and `wantipv6` and set `ipv4`,
    # `ipv6`, `status-ipv4`, and `status-ipv6`.)  It always succeeds.
    legacy => ddclient::LegacyProtocol->new(
        update => sub {
            my $self = shift;
            ddclient::debug('in update');
            push(@updates, [@_]);
            for my $h (@_) {
                local $ddclient::_l = ddclient::pushlogctx($h);
                ddclient::debug('updating host');
                $ddclient::recap{$h}{status} = 'good';
                $ddclient::recap{$h}{ip} = delete($ddclient::config{$h}{wantip});
                $ddclient::recap{$h}{mtime} = $ddclient::now;
            }
            ddclient::debug('returning from update');
        },
    ),
);

my @test_cases = (
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, fresh, $desc",
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            want_updates => [['host']],
            want_recap_changes => {host => {
                'atime' => $ddclient::now,
                'ipv4' => '192.0.2.1',
                'mtime' => $ddclient::now,
                'status-ipv4' => 'good',
            }},
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    {
        desc => 'legacy, fresh, use=web (IPv6)',
        ipv6 => 1,
        cfg => {host => {
            'protocol' => 'legacy',
            'use' => 'web',
            'web' => 'v6',
        }},
        want_reqs_webv6 => 1,
        want_updates => [['host']],
        want_recap_changes => {host => {
            'atime' => $ddclient::now,
            'ipv6' => '2001:db8::1',
            'mtime' => $ddclient::now,
            'status-ipv6' => 'good',
        }},
    },
    {
        desc => 'legacy, fresh, usev6=webv6',
        ipv6 => 1,
        cfg => {host => {
            'protocol' => 'legacy',
            'usev6' => 'webv6',
        }},
        want_reqs_webv6 => 1,
        want_updates => [['host']],
        want_recap_changes => {host => {
            'atime' => $ddclient::now,
            'ipv6' => '2001:db8::1',
            'mtime' => $ddclient::now,
            'status-ipv6' => 'good',
        }},
    },
    {
        desc => 'legacy, fresh, usev4=webv4 usev6=webv6',
        ipv6 => 1,
        cfg => {host => {
            'protocol' => 'legacy',
            'usev4' => 'webv4',
            'usev6' => 'webv6',
        }},
        want_reqs_webv4 => 1,
        want_reqs_webv6 => 1,
        want_updates => [['host']],
        want_recap_changes => {host => {
            'atime' => $ddclient::now,
            'ipv4' => '192.0.2.1',
            'mtime' => $ddclient::now,
            'status-ipv4' => 'good',
        }},
    },
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, no change, not yet time, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-interval'),
                'ipv4' => '192.0.2.1',
                'mtime' => $ddclient::now - ddclient::opt('min-interval'),
                'status-ipv4' => 'good',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, min-interval elapsed but no change, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-interval') - 1,
                'ipv4' => '192.0.2.1',
                'mtime' => $ddclient::now - ddclient::opt('min-interval') - 1,
                'status-ipv4' => 'good',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, needs update, not yet time, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-interval'),
                'ipv4' => '192.0.2.2',
                'mtime' => $ddclient::now - ddclient::opt('min-interval'),
                'status-ipv4' => 'good',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            want_recap_changes => {host => {
                'warned-min-interval' => $ddclient::now,
            }},
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, min-interval elapsed, needs update, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-interval') - 1,
                'ipv4' => '192.0.2.2',
                'mtime' => $ddclient::now - ddclient::opt('min-interval') - 1,
                'status-ipv4' => 'good',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            want_updates => [['host']],
            want_recap_changes => {host => {
                'atime' => $ddclient::now,
                'ipv4' => '192.0.2.1',
                'mtime' => $ddclient::now,
            }},
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, previous failed update, not yet time to retry, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-error-interval'),
                'ipv4' => '192.0.2.2',
                'mtime' => $ddclient::now - max(ddclient::opt('min-error-interval'),
                                                ddclient::opt('min-interval')) - 1,
                'status-ipv4' => 'failed',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            want_recap_changes => {host => {
                'warned-min-error-interval' => $ddclient::now,
            }},
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", keys(%cfg)));
        {
            desc => "legacy, previous failed update, time to retry, $desc",
            recap => {host => {
                'atime' => $ddclient::now - ddclient::opt('min-error-interval') - 1,
                'ipv4' => '192.0.2.2',
                'mtime' => $ddclient::now - ddclient::opt('min-error-interval') - 2,
                'status-ipv4' => 'failed',
            }},
            cfg => {host => {
                'protocol' => 'legacy',
                %cfg,
            }},
            want_reqs_webv4 => 1,
            want_updates => [['host']],
            want_recap_changes => {host => {
                'atime' => $ddclient::now,
                'ipv4' => '192.0.2.1',
                'mtime' => $ddclient::now,
                'status-ipv4' => 'good',
            }},
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    map({
        my %cfg = %{delete($_->{cfg})};
        my $desc = join(' ', map("$_=$cfg{$_}", sort(keys(%cfg))));
        {
            desc => "deduplicates identical IP discovery, $desc",
            cfg => {
                hosta => {protocol => 'legacy', %cfg},
                hostb => {protocol => 'legacy', %cfg},
            },
            want_reqs_webv4 => 1,
            want_updates => [['hosta', 'hostb']],
            want_recap_changes => {
                hosta => {
                    'atime' => $ddclient::now,
                    'ipv4' => '192.0.2.1',
                    'mtime' => $ddclient::now,
                    'status-ipv4' => 'good',
                },
                hostb => {
                    'atime' => $ddclient::now,
                    'ipv4' => '192.0.2.1',
                    'mtime' => $ddclient::now,
                    'status-ipv4' => 'good',
                },
            },
            %$_,
        };
    } {cfg => {use => 'web'}}, {cfg => {usev4 => 'webv4'}}),
    {
        desc => "deduplicates identical IP discovery, usev6=webv6",
        ipv6 => 1,
        cfg => {
            hosta => {protocol => 'legacy', usev6 => 'webv6'},
            hostb => {protocol => 'legacy', usev6 => 'webv6'},
        },
        want_reqs_webv6 => 1,
        want_updates => [['hosta', 'hostb']],
        want_recap_changes => {
            hosta => {
                'atime' => $ddclient::now,
                'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now,
                'status-ipv6' => 'good',
            },
            hostb => {
                'atime' => $ddclient::now,
                'ipv6' => '2001:db8::1',
                'mtime' => $ddclient::now,
                'status-ipv6' => 'good',
            },
        },
    },
);

for my $tc (@test_cases) {
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1) if $tc->{ipv6} && !$httpd_ipv6_supported;
        subtest($tc->{desc} => sub {
            local $ddclient::_l = ddclient::pushlogctx($tc->{desc});
            for my $ipv ('4', '6') {
                $tc->{"want_reqs_webv$ipv"} //= 0;
                my $want = $tc->{"want_reqs_webv$ipv"};
                next if !defined(httpd($ipv)) && $want == 0;
                local $ddclient::_l = ddclient::pushlogctx("IPv$ipv");
                my $ip = $ipv eq '4' ? '192.0.2.1' : '2001:db8::1';
                httpd($ipv)->reset(([200, $textplain, [$ip]]) x $want);
            }
            $tc->{recap}{$_}{host} //= $_ for keys(%{$tc->{recap} // {}});
            # Deep copy `%{$tc->{recap}}` so that updates to `%ddclient::recap` don't mutate it.
            local %ddclient::recap = %{mergecfg($tc->{recap})};
            my $cachef = File::Temp->new();
            # $cachef is an object that stringifies to a filename.
            local $ddclient::globals{cache} = "$cachef";
            $tc->{cfg} = {map({
                ($_ => {
                    host => $_,
                    web => 'v4',
                    webv4 => 'v4',
                    webv6 => 'v6',
                    %{$tc->{cfg}{$_}},
                });
            } keys(%{$tc->{cfg} // {}}))};
            # Deep copy `%{$tc->{cfg}}` so that updates to `%ddclient::config` don't mutate it.
            local %ddclient::config = %{mergecfg($tc->{cfg})};
            local @updates;

            ddclient::update_nics();

            for my $ipv ('4', '6') {
                next if !defined(httpd($ipv));
                local $ddclient::_l = ddclient::pushlogctx("IPv$ipv");
                my @gotreqs = httpd($ipv)->reset();
                my $got = @gotreqs;
                my $want = $tc->{"want_reqs_webv$ipv"};
                is($got, $want, "number of requests to webv$ipv service");
            }
            TODO: {
                local $TODO = $tc->{want_updates_TODO};
                is_deeply(\@updates, $tc->{want_updates} // [], 'got expected updates')
                    or diag(ddclient::repr(Values => [\@updates, $tc->{want_updates}],
                                           Names => ['*got', '*want']));
            }
            my %want_recap = %{mergecfg($tc->{recap}, $tc->{want_recap_changes})};
            TODO: {
                local $TODO = $tc->{want_recap_changes_TODO};
                is_deeply(\%ddclient::recap, \%want_recap, 'recap matches')
                    or diag(ddclient::repr(Values => [\%ddclient::recap, \%want_recap],
                                           Names => ['*got', '*want']));
            }
            my %want_cfg = %{mergecfg($tc->{cfg}, $tc->{want_cfg_changes})};
            TODO: {
                local $TODO = $tc->{want_cfg_changes_TODO};
                is_deeply(\%ddclient::config, \%want_cfg, 'config matches')
                    or diag(ddclient::repr(Values => [\%ddclient::config, \%want_cfg],
                                           Names => ['*got', '*want']));
            }
        });
    }
}

done_testing();
