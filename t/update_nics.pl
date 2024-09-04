use Test::More;
use File::Temp;
use List::Util qw(max);
use Scalar::Util qw(refaddr);
eval { require ddclient::Test::Fake::HTTPD; } or plan(skip_all => $@);
SKIP: { eval { require Test::Warnings; } or skip($@, 1); }
eval { require 'ddclient'; } or BAIL_OUT($@);
my $ipv6_supported = eval {
    require IO::Socket::IP;
    my $ipv6_socket = IO::Socket::IP->new(
        Domain => 'PF_INET6',
        LocalHost => '::1',
        Listen => 1,
    );
    defined($ipv6_socket);
};
my $http_daemon_supports_ipv6 = eval {
    require HTTP::Daemon;
    HTTP::Daemon->VERSION(6.12);
};

sub run_httpd {
    my ($ipv) = @_;
    return undef if $ipv eq '6' && (!$ipv6_supported || !$http_daemon_supports_ipv6);
    my $httpd = ddclient::Test::Fake::HTTPD->new(
        host => $ipv eq '4' ? '127.0.0.1' : '::1',
        daemon_args => {V6Only => 1},
    );
    my $ip = $ipv eq '4' ? '192.0.2.1' : '2001:db8::1';
    $httpd->run(sub { return [200, ['content-type' => 'text/plain; charset=utf-8'], [$ip]]; });
    diag("started IPv$ipv HTTP server running at " . $httpd->endpoint());
    return $httpd;
}
my %httpd = (
    '4' => run_httpd('4'),
    '6' => run_httpd('6'),
);
local %ddclient::builtinweb = (
    v4 => {url => "" . $httpd{'4'}->endpoint()},
    defined($httpd{'6'}) ? (v6 => {url => "" . $httpd{'6'}->endpoint()}) : (),
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
);

for my $tc (@test_cases) {
    SKIP: {
        skip("IPv6 not supported on this system", 1) if $tc->{ipv6} && !$ipv6_supported;
        skip("HTTP::Daemon too old for IPv6 support", 1)
            if $tc->{ipv6} && !$http_daemon_supports_ipv6;
        subtest($tc->{desc} => sub {
            local $ddclient::_l = ddclient::pushlogctx($tc->{desc});
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
