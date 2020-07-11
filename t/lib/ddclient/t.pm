package ddclient::t;
require v5.10.1;
use strict;
use warnings;

our @interface_samples = (
    # Sample output from:
    #   ip -6 -o addr show dev <interface> scope global
    # This seems to be consistent accross platforms. The last line is from Ubuntu of a static
    # assigned IPv6.
    {
        name => 'ip -6 -o addr show dev <interface> scope global',
        text => <<'EOF',
2: ens160    inet6 fdb6:1d86:d9bd:1::8214/128 scope global dynamic noprefixroute \       valid_lft 63197sec preferred_lft 63197sec
2: ens160    inet6 2001:DB8:4341:0781::8214/128 scope global dynamic noprefixroute \       valid_lft 63197sec preferred_lft 63197sec
2: ens160    inet6 2001:DB8:4341:0781:89b9:4b1c:186c:a0c7/64 scope global temporary dynamic \       valid_lft 85954sec preferred_lft 21767sec
2: ens160    inet6 fdb6:1d86:d9bd:1:89b9:4b1c:186c:a0c7/64 scope global temporary dynamic \       valid_lft 85954sec preferred_lft 21767sec
2: ens160    inet6 fdb6:1d86:d9bd:1:34a6:c329:c52e:8ba6/64 scope global temporary deprecated dynamic \       valid_lft 85954sec preferred_lft 0sec
2: ens160    inet6 fdb6:1d86:d9bd:1:b417:fe35:166b:4816/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 85954sec preferred_lft 85954sec
2: ens160    inet6 2001:DB8:4341:0781:34a6:c329:c52e:8ba6/64 scope global temporary deprecated dynamic \       valid_lft 85954sec preferred_lft 0sec
2: ens160    inet6 2001:DB8:4341:0781:f911:a224:7e69:d22/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 85954sec preferred_lft 85954sec
2: ens160    inet6 2001:DB8:4341:0781::100/128 scope global noprefixroute \       valid_lft forever preferred_lft forever
EOF
        want_extract_ipv6_global => '2001:DB8:4341:781::8214',
    },
    # Sample output from MacOS:
    #   ifconfig <interface> | grep -w "inet6"
    # (Yes, there is a tab at start of each line.) The last two lines are with a manually
    # configured static GUA.
    {
        name => 'MacOS: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
	inet6 fe80::1419:abd0:5943:8bbb%en0 prefixlen 64 secured scopeid 0xa
	inet6 fdb6:1d86:d9bd:1:142c:8e9e:de48:843e prefixlen 64 autoconf secured
	inet6 fdb6:1d86:d9bd:1:7447:cf67:edbd:cea4 prefixlen 64 autoconf temporary
	inet6 fdb6:1d86:d9bd:1::c5b3 prefixlen 64 dynamic
	inet6 2001:DB8:4341:0781:141d:66b9:2ba1:b67d prefixlen 64 autoconf secured
	inet6 2001:DB8:4341:0781:64e1:b68f:e8af:5d6e prefixlen 64 autoconf temporary
	inet6 fe80::1419:abd0:5943:8bbb%en0 prefixlen 64 secured scopeid 0xa
	inet6 2001:DB8:4341:0781::101 prefixlen 64
EOF
        want_extract_ipv6_global => '2001:DB8:4341:781:141d:66b9:2ba1:b67d',
    },
    {
        name => 'RHEL: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
        inet6 2001:DB8:4341:0781::dc14  prefixlen 128  scopeid 0x0<global>
        inet6 fe80::cd48:4a58:3b0f:4d30  prefixlen 64  scopeid 0x20<link>
        inet6 2001:DB8:4341:0781:e720:3aec:a936:36d4  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:9c16:8cbf:ae33:f1cc  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1::dc14  prefixlen 128  scopeid 0x0<global>
EOF
        want_extract_ipv6_global => '2001:DB8:4341:781::dc14',
    },
    {
        name => 'Ubuntu: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
        inet6 fdb6:1d86:d9bd:1:34a6:c329:c52e:8ba6  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:89b9:4b1c:186c:a0c7  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1::8214  prefixlen 128  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:b417:fe35:166b:4816  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::5b31:fc63:d353:da68  prefixlen 64  scopeid 0x20<link>
        inet6 2001:DB8:4341:0781::8214  prefixlen 128  scopeid 0x0<global>
        inet6 2001:DB8:4341:0781:34a6:c329:c52e:8ba6  prefixlen 64  scopeid 0x0<global>
        inet6 2001:DB8:4341:0781:89b9:4b1c:186c:a0c7  prefixlen 64  scopeid 0x0<global>
        inet6 2001:DB8:4341:0781:f911:a224:7e69:d22  prefixlen 64  scopeid 0x0<global>
EOF
        want_extract_ipv6_global => '2001:DB8:4341:781::8214',
    },
    {
        name => 'Busybox: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
          inet6 addr: fe80::4362:31ff:fe08:61b4/64 Scope:Link
          inet6 addr: 2001:DB8:4341:0781:ed44:eb63:b070:212f/128 Scope:Global
EOF
        want_extract_ipv6_global => '2001:DB8:4341:781:ed44:eb63:b070:212f',
    },
);
