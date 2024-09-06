package ddclient::t::ip;

use v5.10.1;
use strict;
use warnings;
use Exporter qw(import);
use Test::More;

our @EXPORT = qw(ipv6_ok ipv6_required $ipv6_supported $ipv6_support_error);

our $ipv6_support_error;
our $ipv6_supported = eval {
    require IO::Socket::IP;
    my $ipv6_socket = IO::Socket::IP->new(
        Domain => 'PF_INET6',
        LocalHost => '::1',
        Listen => 1,
    );
    defined($ipv6_socket);
} or $ipv6_support_error = $@;

sub ipv6_ok {
    ok($ipv6_supported, "system supports IPv6") or diag($ipv6_support_error);
}

sub ipv6_required {
    plan(skip_all => $ipv6_support_error) if !$ipv6_supported;
}

1;
