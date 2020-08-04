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

######################################################################
## Outputs from ip route and netstat commands to find default route (and therefore interface)
## Samples from Ubuntu 20.04, RHEL8, Buildroot, Busybox, MacOS 10.15, FreeBSD
## NOTE: Any tabs/whitespace at start or end of lines are intentional to match real life data.
######################################################################
our @routing_samples = (
    {   name => "ip -4 -o route list match default (most linux)",
        text => <<EOF,
default via 198.51.100.1 dev ens33 proto dhcp metric 100 
EOF
        want_ipv4_if => "ens33",
    },
    {   name => "ip -4 -o route list match default (most linux)",
        text => <<EOF,
default via fe80::4262:31ff:fe08:60b3 dev ens33 proto ra metric 20100 pref medium
EOF
        want_ipv4_if => "ens33",
    },
    {   name => "ip -4 -o route list match default (buildroot)",
        text => <<EOF,
default via 198.51.156.1 dev eth0 
EOF
        want_ipv4_if => "eth0",
    },
    {   name => "ip -6 -o route list match default (buildroot)",
        text => <<EOF,
default via fe80::1ee8:5dff:fef4:b822 dev eth0  proto ra  metric 1024  expires 1797sec mtu 1500 hoplimit 64
EOF
        want_ipv6_if => "eth0",
    },
    {   name => "netstat -rn -4 (most linux)",
        text => <<EOF,
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         198.51.100.1    0.0.0.0         UG        0 0          0 ens33
169.254.0.0     0.0.0.0         255.255.0.0     U         0 0          0 ens33
198.51.100.0    0.0.0.0         255.255.255.0   U         0 0          0 ens33
EOF
        want_ipv4_if => "ens33",
    },
    {   name => "netstat -rn -4 (FreeBSD)",
        text => <<EOF,
Routing tables

Internet:
Destination        Gateway            Flags     Netif Expire
default            198.51.100.1       UGS         em0
127.0.0.1          link#2             UH          lo0
198.51.100.0/24    link#1             U           em0
198.51.100.207     link#1             UHS         lo0
EOF
        want_ipv4_if => "em0",
    },
    {   name => "netstat -rn -6 (FreeBSD)",
        text => <<EOF,
Routing tables

Internet6:
Destination                       Gateway                       Flags     Netif Expire
::/96                             ::1                           UGRS        lo0
default                           fe80::4262:31ff:fe08:60b3%em0 UG          em0
::1                               link#2                        UH          lo0
::ffff:0.0.0.0/96                 ::1                           UGRS        lo0
2001:db8:450a:e723::/64           link#1                        U           em0
2001:db8:450a:e723:20c:29ff:fe9f:c532 link#1                    UHS         lo0
fdb6:1d86:d9bd:3::/64             link#1                        U           em0
fdb6:1d86:d9bd:3:20c:29ff:fe9f:c532 link#1                      UHS         lo0
fe80::/10                         ::1                           UGRS        lo0
fe80::%em0/64                     link#1                        U           em0
fe80::20c:29ff:fe9f:c532%em0      link#1                        UHS         lo0
fe80::%lo0/64                     link#2                        U           lo0
fe80::1%lo0                       link#2                        UHS         lo0
ff02::/16                         ::1                           UGRS        lo0
EOF
        want_ipv6_if => "em0",
    },
    {   name => "netstat -rn -6 (most linux)",
        text => <<EOF,
Kernel IPv6 routing table
Destination                    Next Hop                   Flag Met Ref Use If
::1/128                        ::                         U    256 2     0 lo
2001:db8:450a:e723::21/128     ::                         U    100 1     0 ens33
2001:db8:450a:e723::/64        ::                         U    100 4     0 ens33
fdb6:1d86:d9bd:3::21/128       ::                         U    100 1     0 ens33
fdb6:1d86:d9bd:3::/64          ::                         U    100 3     0 ens33
fe80::/64                      ::                         U    100 2     0 ens33
::/0                           fe80::4262:31ff:fe08:60b3  UG   20100 5     0 ens33
::1/128                        ::                         Un   0   4     0 lo
2001:db8:450a:e723::21/128     ::                         Un   0   4     0 ens33
2001:db8:450a:e723:514:cbd9:c55f:8e2a/128 ::                         Un   0   4     0 ens33
2001:db8:450a:e723:adee:be82:7fba:ffb2/128 ::                         Un   0   3     0 ens33
2001:db8:450a:e723:dbc5:1c4e:9e9b:97a2/128 ::                         Un   0   3     0 ens33
fdb6:1d86:d9bd:3::21/128       ::                         Un   0   2     0 ens33
fdb6:1d86:d9bd:3:514:cbd9:c55f:8e2a/128 ::                         Un   0   5     0 ens33
fdb6:1d86:d9bd:3:a1fd:1ed9:6211:4268/128 ::                         Un   0   4     0 ens33
fdb6:1d86:d9bd:3:adee:be82:7fba:ffb2/128 ::                         Un   0   2     0 ens33
fe80::32c0:b270:245b:d3b4/128  ::                         Un   0   3     0 ens33
ff00::/8                       ::                         U    256 7     0 ens33
::/0                           ::                         !n   -1  1     0 lo
EOF
        want_ipv6_if => "ens33",
    },
    {   name => "netstat -rn -f inet (MacOS)",
        text => <<EOF,
Routing tables

Internet:
Destination        Gateway            Flags        Netif Expire
default            198.51.100.1       UGSc           en0       
default            198.51.100.1       UGScI          en1       
127                127.0.0.1          UCS            lo0       
127.0.0.1          127.0.0.1          UH             lo0       
169.254            link#4             UCS            en0      !
169.254            link#5             UCSI           en1      !
172.16.114/24      link#15            UC          vmnet8      !
172.16.114.1       0:50:56:c0:0:8     UHLWIi         lo0       
172.16.114.255     ff:ff:ff:ff:ff:ff  UHLWbI      vmnet8      !
198.51.17         link#4             UCS            en0      !
198.51.17         link#5             UCSI           en1      !
198.51.100.1/32    link#4             UCS            en0      !
198.51.100.1       40:62:31:8:60:b3   UHLWIir        en0   1180
198.51.100.1       40:62:31:8:60:b3   UHLWIir        en1   1160
198.51.100.1/32    link#5             UCSI           en1      !
198.51.100.2       0:c:29:47:b8:d1    UHLWI          en0   1108
198.51.100.5/32    link#4             UCS            en0      !
198.51.100.5       00:00:00:90:32:8f  UHLWIi         lo0       
198.51.100.5       00:00:00:90:32:8f  UHLWI          en1   1182
198.51.100.6       0:8:9b:ee:d4:e     UHLWIi         en0    158
198.51.100.12      0:c:29:70:89:8b    UHLWI          en0   1107
198.51.100.33      0:c:29:da:24:b1    UHLWI          en0   1108
198.51.100.34      0:c:29:6d:aa:8b    UHLWI          en0   1107
198.51.100.137     70:ea:5a:79:45:4b  UHLWI          en0    317
198.51.100.137     70:ea:5a:79:45:4b  UHLWI          en1    561
198.51.100.152     8c:79:67:a7:c4:45  UHLWI          en0    376
198.51.100.155     f0:18:98:29:ef:a3  UHLWIi         en0    694
198.51.100.167     a0:2:dc:f7:7a:9a   UHLWI          en0   1160
198.51.100.167     a0:2:dc:f7:7a:9a   UHLWI          en1   1161
198.51.100.184     8:66:98:92:0:55    UHLWIi         en0    644
198.51.100.187     link#4             UHLWIi         en0      !
198.51.100.187     link#5             UHLWIi         en1      !
198.51.100.199/32  link#5             UCS            en1      !
198.51.100.199     c8:e0:eb:42:96:eb  UHLWIi         lo0       
198.51.100.201     90:e1:7b:b9:e5:38  UHLWI          en0   1182
198.51.100.201     90:e1:7b:b9:e5:38  UHLWI          en1   1182
198.51.100.210     0:61:71:cd:0:10    UHLWI          en0    112
198.51.100.210     0:61:71:cd:0:10    UHLWI          en1    112
198.51.100.211     8c:85:90:55:49:a7  UHLWIi         en0    762
198.51.100.211     8c:85:90:55:49:a7  UHLWI          en1    762
198.51.100.240     f0:18:98:20:f9:d7  UHLWIi         en0   1172
198.51.100.240     f0:18:98:20:f9:d7  UHLWIi         en1   1173
198.51.100.241     e0:33:8e:38:44:3   UHLWIi         en0    961
198.51.100.241     e0:33:8e:38:44:3   UHLWI          en1    961
198.51.100.242     98:1:a7:49:1e:1c   UHLWIi         en0    899
198.51.100.242     98:1:a7:49:1e:1c   UHLWIi         en1    899
198.51.100.255     ff:ff:ff:ff:ff:ff  UHLWbI         en0      !
198.51.196        link#14            UC          vmnet1      !
198.51.196.1      0:50:56:c0:0:1     UHLWIi         lo0       
198.51.196.255    ff:ff:ff:ff:ff:ff  UHLWbI      vmnet1      !
224.0.0/4          link#4             UmCS           en0      !
224.0.0/4          link#5             UmCSI          en1      !
224.0.0.251        1:0:5e:0:0:fb      UHmLWI         en0       
224.0.0.251        1:0:5e:0:0:fb      UHmLWI         en1       
239.255.255.250    1:0:5e:7f:ff:fa    UHmLWI         en0       
239.255.255.250    1:0:5e:7f:ff:fa    UHmLWI         en1       
255.255.255.255/32 link#4             UCS            en0      !
255.255.255.255    ff:ff:ff:ff:ff:ff  UHLWbI         en0      !
255.255.255.255/32 link#5             UCSI           en1      !
EOF
        want_ipv4_if => "en0",
    },
    {   name => "netstat -rn -f inet6 (MacOS)",
        text => <<EOF,
Routing tables

Internet6:
Destination                             Gateway                         Flags         Netif Expire
default                                 fe80::4262:31ff:fe08:60b3%en0   UGc             en0       
default                                 fe80::4262:31ff:fe08:60b3%en1   UGcI            en1       
default                                 fe80::%utun0                    UGcI          utun0       
default                                 fe80::%utun1                    UGcI          utun1       
::1                                     ::1                             UHL             lo0       
2001:db8:450a:e723::/64                 link#4                          UC              en0       
2001:db8:450a:e723::/64                 link#5                          UCI             en1       
2001:db8:450a:e723::1                   40:62:31:8:60:b3                UHLWIi          en0       
2001:db8:450a:e723:208:9bff:feee:d40e   0:8:9b:ee:d4:e                  UHLWI           en0       
2001:db8:450a:e723:208:9bff:feee:d40f   0:8:9b:ee:d4:f                  UHLWI           en0       
2001:db8:450a:e723:881:db49:835c:e83e   c8:e0:eb:42:96:eb               UHL             lo0       
2001:db8:450a:e723:1820:2961:5878:fb72  c8:e0:eb:42:96:eb               UHL             lo0       
2001:db8:450a:e723:1c99:99e2:21d0:79e6  00:00:00:90:32:8f               UHL             lo0       
2001:db8:450a:e723:2474:39fd:f5c0:6845  00:00:00:90:32:8f               UHL             lo0       
2001:db8:450a:e723:808d:d894:e4db:157e  00:00:00:90:32:8f               UHL             lo0       
2001:db8:450a:e723:9022:cdf6:728c:81cc  c8:e0:eb:42:96:eb               UHL             lo0       
fdb6:1d86:d9bd:3::/64                   link#4                          UC              en0       
fdb6:1d86:d9bd:3::/64                   link#5                          UCI             en1       
fdb6:1d86:d9bd:3::1                     40:62:31:8:60:b3                UHLWI           en0       
fdb6:1d86:d9bd:3::8076                  00:00:00:90:32:8f               UHL             lo0       
fdb6:1d86:d9bd:3::85ba                  c8:e0:eb:42:96:eb               UHL             lo0       
fdb6:1d86:d9bd:3:208:9bff:feee:d40e     0:8:9b:ee:d4:e                  UHLWI           en0       
fdb6:1d86:d9bd:3:208:9bff:feee:d40f     0:8:9b:ee:d4:f                  UHLWI           en0       
fdb6:1d86:d9bd:3:837:e1c7:4895:269e     00:00:00:90:32:8f               UHL             lo0       
fdb6:1d86:d9bd:3:8a5:4e16:4924:ca7d     c8:e0:eb:42:96:eb               UHL             lo0       
fdb6:1d86:d9bd:3:dbb:dd72:928a:1f4      c8:e0:eb:42:96:eb               UHL             lo0       
fdb6:1d86:d9bd:3:2474:39fd:f5c0:6845    00:00:00:90:32:8f               UHL             lo0       
fdb6:1d86:d9bd:3:9022:cdf6:728c:81cc    c8:e0:eb:42:96:eb               UHL             lo0       
fdb6:1d86:d9bd:3:a0b3:aa4d:9e76:e1ab    00:00:00:90:32:8f               UHL             lo0       
fe80::%lo0/64                           fe80::1%lo0                     UcI             lo0       
fe80::1%lo0                             link#1                          UHLI            lo0       
fe80::%en0/64                           link#4                          UCI             en0       
fe80::2e:996d:54e6:daa0%en0             70:ea:5a:79:45:4b               UHLWI           en0       
fe80::208:9bff:feee:d40f%en0            0:8:9b:ee:d4:f                  UHLWI           en0       
fe80::4ba:362c:664:c432%en0             7c:a1:ae:f:4:f4                 UHLWI           en0       
fe80::85b:d150:cdd9:3198%en0            00:00:00:90:32:8f               UHLI            lo0       
fe80::8f2:20e6:a10b:3cdd%en0            70:56:81:ba:5f:37               UHLWI           en0       
fe80::c20:19a:2ac2:79a1%en0             cc:d2:81:5a:8d:ee               UHLWI           en0       
fe80::10e4:937a:51ce:a8d9%en0           f0:18:98:29:ef:a3               UHLWI           en0       
fe80::142a:3ac5:7cb9:2218%en0           90:e1:7b:b9:e5:38               UHLWI           en0       
fe80::1445:78b9:1d5c:11eb%en0           c8:e0:eb:42:96:eb               UHLWI           en0       
fe80::1450:3f80:6143:4f7c%en0           b8:e8:56:a3:67:5                UHLWI           en0       
fe80::18d5:2b64:b66b:88b%en0            e0:33:8e:38:44:3                UHLWI           en0       
fe80::1c88:3c7:f97b:e538%en0            98:1:a7:49:1e:1c                UHLWIi          en0       
fe80::4262:31ff:fe08:60b3%en0           40:62:31:8:60:b3                UHLWIir         en0       
fe80::%en1/64                           link#5                          UCI             en1       
fe80::2e:996d:54e6:daa0%en1             70:ea:5a:79:45:4b               UHLWI           en1       
fe80::70:2494:f602:7479%en1             0:61:71:cd:0:10                 UHLWI           en1       
fe80::4ba:362c:664:c432%en1             7c:a1:ae:f:4:f4                 UHLWI           en1       
fe80::85b:d150:cdd9:3198%en1            00:00:00:90:32:8f               UHLWI           en1       
fe80::8f2:20e6:a10b:3cdd%en1            70:56:81:ba:5f:37               UHLWI           en1       
fe80::c20:19a:2ac2:79a1%en1             cc:d2:81:5a:8d:ee               UHLWI           en1       
fe80::1445:78b9:1d5c:11eb%en1           c8:e0:eb:42:96:eb               UHLI            lo0       
fe80::18d5:2b64:b66b:88b%en1            e0:33:8e:38:44:3                UHLWI           en1       
fe80::1c88:3c7:f97b:e538%en1            98:1:a7:49:1e:1c                UHLWIi          en1       
fe80::4262:31ff:fe08:60b3%en1           40:62:31:8:60:b3                UHLWIir         en1       
fe80::%awdl0/64                         link#10                         UCI           awdl0       
fe80::54df:1aff:fee1:2df5%awdl0         56:df:1a:e1:2d:f5               UHLI            lo0       
fe80::%llw0/64                          link#11                         UCI            llw0       
fe80::54df:1aff:fee1:2df5%llw0          56:df:1a:e1:2d:f5               UHLI            lo0       
fe80::%utun0/64                         fe80::aeea:9fe9:9194:6e66%utun0 UcI           utun0       
fe80::aeea:9fe9:9194:6e66%utun0         link#12                         UHLI            lo0       
fe80::%utun1/64                         fe80::583f:da5f:e2bc:4773%utun1 UcI           utun1       
fe80::583f:da5f:e2bc:4773%utun1         link#13                         UHLI            lo0       
ff01::%lo0/32                           ::1                             UmCI            lo0       
ff01::%en0/32                           link#4                          UmCI            en0       
ff01::%en1/32                           link#5                          UmCI            en1       
ff01::%awdl0/32                         link#10                         UmCI          awdl0       
ff01::%llw0/32                          link#11                         UmCI           llw0       
ff01::%utun0/32                         fe80::aeea:9fe9:9194:6e66%utun0 UmCI          utun0       
ff01::%utun1/32                         fe80::583f:da5f:e2bc:4773%utun1 UmCI          utun1       
ff02::%lo0/32                           ::1                             UmCI            lo0       
ff02::%en0/32                           link#4                          UmCI            en0       
ff02::%en1/32                           link#5                          UmCI            en1       
ff02::%awdl0/32                         link#10                         UmCI          awdl0       
ff02::%llw0/32                          link#11                         UmCI           llw0       
ff02::%utun0/32                         fe80::aeea:9fe9:9194:6e66%utun0 UmCI          utun0       
ff02::%utun1/32                         fe80::583f:da5f:e2bc:4773%utun1 UmCI          utun1   
EOF
        want_ipv6_if => "en0",
    },
);
