package ddclient::t;
require v5.10.1;
use strict;
use warnings;


######################################################################
## Outputs from ip addr and ifconfig commands to find IP address from IF name
## Samples from Ubuntu 20.04, RHEL8, Buildroot, Busybox, MacOS 10.15, FreeBSD
## NOTE: Any tabs/whitespace at start or end of lines are intentional to match real life data.
######################################################################
our @interface_samples = (
    # This seems to be consistent accross platforms. The last line is from Ubuntu of a static
    # assigned IPv6.
    {
        name => 'ip -6 -o addr show dev <interface> scope global',
        text => <<'EOF',
2: ens160    inet6 fdb6:1d86:d9bd:1::8214/128 scope global dynamic noprefixroute \       valid_lft 63197sec preferred_lft 63197sec
2: ens160    inet6 2001:db8:4341:0781::8214/128 scope global dynamic noprefixroute \       valid_lft 63197sec preferred_lft 63197sec
2: ens160    inet6 2001:db8:4341:0781:89b9:4b1c:186c:a0c7/64 scope global temporary dynamic \       valid_lft 85954sec preferred_lft 21767sec
2: ens160    inet6 fdb6:1d86:d9bd:1:89b9:4b1c:186c:a0c7/64 scope global temporary dynamic \       valid_lft 85954sec preferred_lft 21767sec
2: ens160    inet6 fdb6:1d86:d9bd:1:34a6:c329:c52e:8ba6/64 scope global temporary deprecated dynamic \       valid_lft 85954sec preferred_lft 0sec
2: ens160    inet6 fdb6:1d86:d9bd:1:b417:fe35:166b:4816/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 85954sec preferred_lft 85954sec
2: ens160    inet6 2001:db8:4341:0781:34a6:c329:c52e:8ba6/64 scope global temporary deprecated dynamic \       valid_lft 85954sec preferred_lft 0sec
2: ens160    inet6 2001:db8:4341:0781:f911:a224:7e69:d22/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 85954sec preferred_lft 85954sec
2: ens160    inet6 2001:db8:4341:0781::100/128 scope global noprefixroute \       valid_lft forever preferred_lft forever
EOF
        want_extract_ipv6_global => '2001:db8:4341:781::8214',
        want_ipv6gua_from_if => "2001:db8:4341:781::100",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:1::8214",
    },
    # (Yes, there is a tab at start of each line.) The last lines is with a manually
    # configured static GUA.
    {
        name => 'MacOS: ifconfig <interface> | grep -w inet6',
        MacOS => 1,
        text => <<'EOF',
	inet6 fe80::1419:abd0:5943:8bbb%en0 prefixlen 64 secured scopeid 0xa
	inet6 fdb6:1d86:d9bd:1:142c:8e9e:de48:843e prefixlen 64 autoconf secured
	inet6 fdb6:1d86:d9bd:1:7447:cf67:edbd:cea4 prefixlen 64 autoconf temporary
	inet6 fdb6:1d86:d9bd:1::c5b3 prefixlen 64 dynamic
	inet6 2001:db8:4341:0781:141d:66b9:2ba1:b67d prefixlen 64 autoconf secured
	inet6 2001:db8:4341:0781:64e1:b68f:e8af:5d6e prefixlen 64 autoconf temporary
	inet6 2001:db8:4341:0781::101 prefixlen 64
EOF
        want_extract_ipv6_global => '2001:db8:4341:781:141d:66b9:2ba1:b67d',
        want_ipv6gua_from_if => "2001:db8:4341:781::101",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:1::c5b3",
    },
    {
        name => 'RHEL: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
        inet6 2001:db8:4341:0781::dc14  prefixlen 128  scopeid 0x0<global>
        inet6 fe80::cd48:4a58:3b0f:4d30  prefixlen 64  scopeid 0x20<link>
        inet6 2001:db8:4341:0781:e720:3aec:a936:36d4  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:9c16:8cbf:ae33:f1cc  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1::dc14  prefixlen 128  scopeid 0x0<global>
EOF
        want_extract_ipv6_global => '2001:db8:4341:781::dc14',
        want_ipv6gua_from_if => "2001:db8:4341:781::dc14",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:1::dc14",
    },
    {
        name => 'Ubuntu: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
        inet6 fdb6:1d86:d9bd:1:34a6:c329:c52e:8ba6  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:89b9:4b1c:186c:a0c7  prefixlen 64  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1::8214  prefixlen 128  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:1:b417:fe35:166b:4816  prefixlen 64  scopeid 0x0<global>
        inet6 fe80::5b31:fc63:d353:da68  prefixlen 64  scopeid 0x20<link>
        inet6 2001:db8:4341:0781::8214  prefixlen 128  scopeid 0x0<global>
        inet6 2001:db8:4341:0781:34a6:c329:c52e:8ba6  prefixlen 64  scopeid 0x0<global>
        inet6 2001:db8:4341:0781:89b9:4b1c:186c:a0c7  prefixlen 64  scopeid 0x0<global>
        inet6 2001:db8:4341:0781:f911:a224:7e69:d22  prefixlen 64  scopeid 0x0<global>
EOF
        want_extract_ipv6_global => '2001:db8:4341:781::8214',
        want_ipv6gua_from_if => "2001:db8:4341:781::8214",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:1::8214",
    },
    {
        name => 'Busybox: ifconfig <interface> | grep -w inet6',
        text => <<'EOF',
          inet6 addr: fe80::4362:31ff:fe08:61b4/64 Scope:Link
          inet6 addr: 2001:db8:4341:781:ed44:eb63:b070:212f/128 Scope:Global
EOF
        want_extract_ipv6_global => '2001:db8:4341:781:ed44:eb63:b070:212f',
        want_ipv6gua_from_if => "2001:db8:4341:781:ed44:eb63:b070:212f",
    },
    {   name => "ip -4 -o addr show dev ens33 scope global (most linux IPv4)",
        text => <<EOF,
2: ens33    inet 198.51.100.33/24 brd 198.51.100.255 scope global dynamic noprefixroute ens33\       valid_lft 77760sec preferred_lft 77760sec
EOF
        want_ipv4_from_if => "198.51.100.33",
    },
    {   name => "ip -6 -o addr show dev ens33 scope global (most linux)",
        text => <<EOF,
2: ens33    inet6 2001:db8:450a:e723:adee:be82:7fba:ffb2/64 scope global temporary dynamic \       valid_lft 86282sec preferred_lft 81094sec
2: ens33    inet6 fdb6:1d86:d9bd:3:adee:be82:7fba:ffb2/64 scope global temporary dynamic \       valid_lft 86282sec preferred_lft 81094sec
2: ens33    inet6 fdb6:1d86:d9bd:3::21/128 scope global dynamic noprefixroute \       valid_lft 76832sec preferred_lft 76832sec
2: ens33    inet6 2001:db8:450a:e723::21/128 scope global dynamic noprefixroute \       valid_lft 76832sec preferred_lft 76832sec
2: ens33    inet6 fdb6:1d86:d9bd:3:514:cbd9:c55f:8e2a/64 scope global temporary deprecated dynamic \       valid_lft 86282sec preferred_lft 0sec
2: ens33    inet6 fdb6:1d86:d9bd:3:a1fd:1ed9:6211:4268/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 86282sec preferred_lft 86282sec
2: ens33    inet6 2001:db8:450a:e723:514:cbd9:c55f:8e2a/64 scope global temporary deprecated dynamic \       valid_lft 86282sec preferred_lft 0sec
2: ens33    inet6 2001:db8:450a:e723:dbc5:1c4e:9e9b:97a2/64 scope global dynamic mngtmpaddr noprefixroute \       valid_lft 86282sec preferred_lft 86282sec
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:adee:be82:7fba:ffb2",
        want_ipv6gua_from_if => "2001:db8:450a:e723::21",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3::21",
    },
    {   name => "ip -6 -o addr show dev ens33 scope global (most linux static IPv6)",
        text => <<EOF,
2: ens33    inet6 2001:db8:450a:e723::101/64 scope global noprefixroute \       valid_lft forever preferred_lft forever
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723::101",
        want_ipv6gua_from_if => "2001:db8:450a:e723::101",
    },
    {   name => "ifconfig ens33 (most linux autoconf IPv6 and DHCPv6)",
        text => <<EOF,
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 198.51.100.33  netmask 255.255.255.0  broadcast 198.51.100.255
        inet6 fdb6:1d86:d9bd:3::21  prefixlen 128  scopeid 0x0<global>
        inet6 fe80::32c0:b270:245b:d3b4  prefixlen 64  scopeid 0x20<link>
        inet6 fdb6:1d86:d9bd:3:a1fd:1ed9:6211:4268  prefixlen 64  scopeid 0x0<global>
        inet6 2001:db8:450a:e723:adee:be82:7fba:ffb2  prefixlen 64  scopeid 0x0<global>
        inet6 2001:db8:450a:e723::21  prefixlen 128  scopeid 0x0<global>
        inet6 fdb6:1d86:d9bd:3:adee:be82:7fba:ffb2  prefixlen 64  scopeid 0x0<global>
        inet6 2001:db8:450a:e723:dbc5:1c4e:9e9b:97a2  prefixlen 64  scopeid 0x0<global>
        ether 00:00:00:da:24:b1  txqueuelen 1000  (Ethernet)
        RX packets 3782541  bytes 556082941 (556.0 MB)
        RX errors 0  dropped 513  overruns 0  frame 0
        TX packets 33294  bytes 6838768 (6.8 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:adee:be82:7fba:ffb2",
        want_ipv6gua_from_if => "2001:db8:450a:e723::21",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3::21",
        want_ipv4_from_if => "198.51.100.33",
    },
    {   name => "ifconfig ens33 (most linux DHCPv6)",
        text => <<EOF,
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 198.51.100.33  netmask 255.255.255.0  broadcast 198.51.100.255
        inet6 fdb6:1d86:d9bd:3::21  prefixlen 128  scopeid 0x0<global>
        inet6 fe80::32c0:b270:245b:d3b4  prefixlen 64  scopeid 0x20<link>
        inet6 2001:db8:450a:e723::21  prefixlen 128  scopeid 0x0<global>
        ether 00:00:00:da:24:b1  txqueuelen 1000  (Ethernet)
        RX packets 3781554  bytes 555602847 (555.6 MB)
        RX errors 0  dropped 513  overruns 0  frame 0
        TX packets 32493  bytes 6706131 (6.7 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723::21",
        want_ipv6gua_from_if => "2001:db8:450a:e723::21",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3::21",
        want_ipv4_from_if => "198.51.100.33",
    },
    {   name => "ifconfig ens33 (most linux static IPv6)",
        text => <<EOF,
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 198.51.100.33  netmask 255.255.255.0  broadcast 198.51.100.255
        inet6 fe80::32c0:b270:245b:d3b4  prefixlen 64  scopeid 0x20<link>
        inet6 2001:db8:450a:e723::101  prefixlen 64  scopeid 0x0<global>
        ether 00:00:00:da:24:b1  txqueuelen 1000  (Ethernet)
        RX packets 3780219  bytes 554967876 (554.9 MB)
        RX errors 0  dropped 513  overruns 0  frame 0
        TX packets 31556  bytes 6552122 (6.5 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723::101",
        want_ipv6gua_from_if => "2001:db8:450a:e723::101",
        want_ipv4_from_if => "198.51.100.33",
    },
    {   name => "ifconfig en0 (MacOS IPv4)",
        text => <<EOF,
en0: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 9000
	options=50b<RXCSUM,TXCSUM,VLAN_HWTAGGING,AV,CHANNEL_IO>
	ether 00:00:00:90:32:8f 
	inet6 fe80::85b:d150:cdd9:3198%en0 prefixlen 64 secured scopeid 0x4 
	inet6 2001:db8:450a:e723:1c99:99e2:21d0:79e6 prefixlen 64 autoconf secured 
	inet6 2001:db8:450a:e723:808d:d894:e4db:157e prefixlen 64 deprecated autoconf temporary 
	inet6 fdb6:1d86:d9bd:3:837:e1c7:4895:269e prefixlen 64 autoconf secured 
	inet6 fdb6:1d86:d9bd:3:a0b3:aa4d:9e76:e1ab prefixlen 64 deprecated autoconf temporary 
	inet 198.51.100.5 netmask 0xffffff00 broadcast 198.51.100.255
	inet6 2001:db8:450a:e723:2474:39fd:f5c0:6845 prefixlen 64 autoconf temporary 
	inet6 fdb6:1d86:d9bd:3:2474:39fd:f5c0:6845 prefixlen 64 autoconf temporary 
	inet6 fdb6:1d86:d9bd:3::8076 prefixlen 64 dynamic 
	nd6 options=201<PERFORMNUD,DAD>
	media: 1000baseT <full-duplex,flow-control,energy-efficient-ethernet>
	status: active
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:1c99:99e2:21d0:79e6",
        want_ipv6gua_from_if => "2001:db8:450a:e723:1c99:99e2:21d0:79e6",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3::8076",
        want_ipv4_from_if => "198.51.100.5",
    },
    {   name => "ifconfig em0 (FreeBSD IPv4)",
        text => <<EOF,
em0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
	options=81009b<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,VLAN_HWCSUM,VLAN_HWFILTER>
	ether 00:00:00:9f:c5:32
	inet6 fe80::20c:29ff:fe9f:c532%em0 prefixlen 64 scopeid 0x1
	inet6 2001:db8:450a:e723:20c:29ff:fe9f:c532 prefixlen 64 autoconf
	inet6 fdb6:1d86:d9bd:3:20c:29ff:fe9f:c532 prefixlen 64 autoconf
	inet 198.51.100.207 netmask 0xffffff00 broadcast 198.51.100.255
	media: Ethernet autoselect (1000baseT <full-duplex>)
	status: active
	nd6 options=23<PERFORMNUD,ACCEPT_RTADV,AUTO_LINKLOCAL>
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:20c:29ff:fe9f:c532",
        want_ipv6gua_from_if => "2001:db8:450a:e723:20c:29ff:fe9f:c532",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3:20c:29ff:fe9f:c532",
        want_ipv4_from_if => "198.51.100.207",
    },
    {   name => "ifconfig -L en0 (MacOS autoconf IPv6)",
        MacOS => 1,
        text => <<EOF,
en0: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 9000
	options=50b<RXCSUM,TXCSUM,VLAN_HWTAGGING,AV,CHANNEL_IO>
	ether 00:00:00:90:32:8f 
	inet6 fe80::85b:d150:cdd9:3198%en0 prefixlen 64 secured scopeid 0x4 
	inet6 2001:db8:450a:e723:1c99:99e2:21d0:79e6 prefixlen 64 autoconf secured pltime 86205 vltime 86205 
	inet6 2001:db8:450a:e723:808d:d894:e4db:157e prefixlen 64 deprecated autoconf temporary pltime 0 vltime 86205 
	inet6 fdb6:1d86:d9bd:3:837:e1c7:4895:269e prefixlen 64 autoconf secured pltime 86205 vltime 86205 
	inet6 fdb6:1d86:d9bd:3:a0b3:aa4d:9e76:e1ab prefixlen 64 deprecated autoconf temporary pltime 0 vltime 86205 
	inet 198.51.100.5 netmask 0xffffff00 broadcast 198.51.100.255
	inet6 2001:db8:450a:e723:2474:39fd:f5c0:6845 prefixlen 64 autoconf temporary pltime 76882 vltime 86205 
	inet6 fdb6:1d86:d9bd:3:2474:39fd:f5c0:6845 prefixlen 64 autoconf temporary pltime 76882 vltime 86205 
	inet6 fdb6:1d86:d9bd:3::8076 prefixlen 64 dynamic pltime 78010 vltime 78010 
	nd6 options=201<PERFORMNUD,DAD>
	media: 1000baseT <full-duplex,flow-control,energy-efficient-ethernet>
	status: active
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:1c99:99e2:21d0:79e6",
        want_ipv6gua_from_if => "2001:db8:450a:e723:1c99:99e2:21d0:79e6",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3::8076",
        want_ipv4_from_if => "198.51.100.5",
    },
    {   name => "ifconfig -L en0 (MacOS static IPv6)",
        MacOS => 1,
        text => <<EOF,
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
	ether 00:00:00:42:96:eb 
	inet 198.51.100.199 netmask 0xffffff00 broadcast 198.51.100.255
	inet6 fe80::1445:78b9:1d5c:11eb%en1 prefixlen 64 secured scopeid 0x5 
	inet6 2001:db8:450a:e723::100 prefixlen 64 
	nd6 options=201<PERFORMNUD,DAD>
	media: autoselect
	status: active
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723::100",
        want_ipv6gua_from_if => "2001:db8:450a:e723::100",
        want_ipv4_from_if => "198.51.100.199",
    },
    {   name => "ifconfig -L em0 (FreeBSD autoconf IPv6)",
        MacOS => 1,
        text => <<EOF,
em0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
	options=81009b<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,VLAN_HWCSUM,VLAN_HWFILTER>
	ether 00:00:00:9f:c5:32
	inet6 fe80::20c:29ff:fe9f:c532%em0 prefixlen 64 scopeid 0x1
	inet6 2001:db8:450a:e723:20c:29ff:fe9f:c532 prefixlen 64 autoconf pltime 86114 vltime 86114
	inet6 fdb6:1d86:d9bd:3:20c:29ff:fe9f:c532 prefixlen 64 autoconf pltime 86114 vltime 86114
	inet 198.51.100.207 netmask 0xffffff00 broadcast 198.51.100.255
	media: Ethernet autoselect (1000baseT <full-duplex>)
	status: active
	nd6 options=23<PERFORMNUD,ACCEPT_RTADV,AUTO_LINKLOCAL>
EOF
        want_extract_ipv6_global => "2001:db8:450a:e723:20c:29ff:fe9f:c532",
        want_ipv6gua_from_if => "2001:db8:450a:e723:20c:29ff:fe9f:c532",
        want_ipv6ula_from_if => "fdb6:1d86:d9bd:3:20c:29ff:fe9f:c532",
        want_ipv4_from_if => "198.51.100.207",
    },
    {   name => "ip -4 -o addr show dev eth0 scope global (Buildroot IPv4)",
        text => <<EOF,
2: eth0    inet 198.51.157.237/22 brd 255.255.255.255 scope global eth0\       valid_lft forever preferred_lft forever
EOF
        want_ipv4_from_if => "198.51.157.237",
    },
    {   name => "ip -6 -o addr show dev eth0 scope global (Buildroot IPv6)",
        text => <<EOF,
2: eth0    inet6 2001:db8:450b:13f:ed44:eb63:b070:212f/128 scope global \       valid_lft forever preferred_lft forever
EOF
        want_extract_ipv6_global => "2001:db8:450b:13f:ed44:eb63:b070:212f",
        want_ipv6gua_from_if => "2001:db8:450b:13f:ed44:eb63:b070:212f",
    },
    {   name => "ifconfig eth0 (Busybox)",
        text => <<EOF,
eth0      Link encap:Ethernet  HWaddr 00:00:00:08:60:B4  
          inet addr:198.51.157.237  Bcast:255.255.255.255  Mask:255.255.252.0
          inet6 addr: fe80::4262:31ff:fe08:60b4/64 Scope:Link
          inet6 addr: 2001:db8:450b:13f:ed44:eb63:b070:212f/128 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:9000  Metric:1
          RX packets:33209620 errors:0 dropped:0 overruns:0 frame:0
          TX packets:14638979 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:41724254079 (38.8 GiB)  TX bytes:3221012240 (2.9 GiB)
EOF
        want_extract_ipv6_global => "2001:db8:450b:13f:ed44:eb63:b070:212f",
        want_ipv6gua_from_if => "2001:db8:450b:13f:ed44:eb63:b070:212f",
        want_ipv4_from_if => "198.51.157.237",
    },
);
