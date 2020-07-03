===============================================================================
# DDCLIENT v3.9.1

ddclient is a Perl client used to update dynamic DNS entries for accounts
on many dynamic DNS services.

===============================================================================

Dynamic DNS services currently supported include:

    DynDNS.com  - See http://www.dyndns.com for details on obtaining a free account.
    Hammernode  - See http://www.hn.org for details on obtaining a free account.
    Zoneedit    - See http://www.zoneedit.com for details.
    EasyDNS     - See http://www.easydns.com for details.
    NameCheap   - See http://www.namecheap.com for details
    DslReports  - See http://www.dslreports.com for details
    Sitelutions - See http://www.sitelutions.com for details
    Loopia      - See http://www.loopia.se for details
    Noip        - See http://www.noip.com/ for details
    Freedns     - See http://freedns.afraid.org/ for details
    ChangeIP    - See http://www.changeip.com/ for details
    dtdns       - See http://www.dtdns.com/ for details
    nsupdate    - See nsupdate(1) and ddns-confgen(8) for details
    CloudFlare  - See https://www.cloudflare.com/ for details
    Google      - See http://www.google.com/domains for details
    Duckdns     - See https://duckdns.org/ for details
    Freemyip    - See https://freemyip.com for details
    woima.fi    - See https://woima.fi/ for details
    Yandex      - See https://domain.yandex.com/ for details
    DNS Made Easy - See https://dnsmadeeasy.com/ for details
    DonDominio  - See https://www.dondominio.com for details
    NearlyFreeSpeech.net - See https://www.nearlyfreespeech.net/services/dns for details
    OVH         - See https://www.ovh.com for details
    ClouDNS     - See https://www.cloudns.net

DDclient now supports many of cable/dsl broadband routers.

Comments, suggestions and requests: use the issues on https://github.com/ddclient/ddclient/issues/new

The code was originally written by Paul Burry and is now hosted and maintained
through github.com. Please check out http://ddclient.net

-------------------------------------------------------------------------------

## REQUIREMENTS

  * An account from a supported dynamic DNS service provider
  * Perl v5.10.1 or later
      * `IO::Socket::SSL` perl library for ssl-support
      * `JSON::PP` perl library for JSON support
      * `IO::Socket:INET6` perl library for ipv6-support
  * Linux, macOS, or any other Unix-ish system
  * An implementation of `make` (such as [GNU
    Make](https://www.gnu.org/software/make/))
  * If you are installing from a clone of the Git repository, you will
    also need [GNU Autoconf](https://www.gnu.org/software/autoconf/)
    and [GNU Automake](https://www.gnu.org/software/automake/).

## DOWNLOAD

See https://github.com/ddclient/ddclient/releases

## INSTALLATION

  1. Extract the distribution tarball (`.tar.gz` file) and `cd` into
     the directory:

     ```shell
     tar xvfa ddclient-3.9.1.tar.gz
     cd ddclient-3.9.1
     ```

     (If you are installing from a clone of the Git repository, you
     must run `./autogen` before continuing to the next step.)

  2. Run the following commands to build and install:

     ```shell
     ./configure \
         --prefix=/usr \
         --sysconfdir=/etc/ddclient \
         --localstatedir=/var
     make
     make VERBOSE=1 check
     sudo make install
     ```

  3. Edit `/etc/ddclient/ddclient.conf`.

### systemd

    cp sample-etc_systemd.service /etc/systemd/system/ddclient.service

enable automatic startup when booting

    systemctl enable ddclient.service

start the first time by hand

    systemctl start ddclient.service

### Redhat style rc files and daemon-mode

    cp sample-etc_rc.d_init.d_ddclient /etc/rc.d/init.d/ddclient

enable automatic startup when booting. also check your distribution

    /sbin/chkconfig --add ddclient

start the first time by hand

    /etc/rc.d/init.d/ddclient start

### Alpine style rc files and daemon-mode

    cp sample-etc_rc.d_init.d_ddclient.alpine /etc/init.d/ddclient

enable automatic startup when booting

    rc-update add ddclient

make sure you have perl installed

    apk add perl

start the first time by hand

    rc-service ddclient start

### Ubuntu style rc files and daemon-mode

    cp sample-etc_rc.d_init.d_ddclient.ubuntu /etc/init.d/ddclient

enable automatic startup when booting

    update-rc.d ddclient defaults

make sure you have perl and the required modules installed

    apt-get install perl libdata-validate-ip-perl libio-socket-ssl-perl

if you plan to use cloudflare or feedns you need the perl json module

    apt-get install libjson-pp-perl

for IPv6 you also need to instal the perl io-socker-inet6 module

    apt install libio-socket-inet6-perl

start the first time by hand

    service ddclient start

### FreeBSD style rc files and daemon mode

    mkdir -p /usr/local/etc/rc.d
    cp sample-etc_rc.d_ddclient.freebsd /usr/local/etc/rc.d/ddclient

enable automatic startup when booting

    sysrc ddclient_enable=YES

make sure you have perl and the required modules installed

    pkg install perl5 p5-Data-Validate-IP p5-IO-Socket-SSL

if you plan to use cloudflare or feedns you need the perl json module

    pkg install p5-JSON-PP

start the service manually for the first time

    service ddclient start


If you are not using daemon-mode, configure cron and dhcp or ppp as described below.

-------------------------------------------------------------------------------

## TROUBLESHOOTING

  1. enable debugging and verbose messages: ``$ ddclient -daemon=0 -debug -verbose -noquiet``

  2. Do you need to specify a proxy?
     If so, just add a ``proxy=your.isp.proxy`` to the ddclient.conf file.

  3. Define the IP address of your router with ``fw=xxx.xxx.xxx.xxx`` in
     ``/etc/ddclient/ddclient.conf`` and then try ``$ ddclient -daemon=0 -query`` to see if the router status web page can be understood.

  4. Need support for another router/firewall?
     Define the router status page yourself with: ``fw=url-to-your-router``'s-status-page ``fw-skip=any-string-preceding-your-IP-address``

     ddclient does something like this to provide builtin support for
     common routers.
     For example, the Linksys routers could have been added with:

    fw=192.168.1.1/Status.htm
    fw-skip=WAN.*?IP Address

OR
     Send me the output from:
      ``$ ddclient -geturl {fw-ip-status-url} [-login login [-password password]]``
     and I'll add it to the next release!

ie. for my fw/router I used: ``$ ddclient -geturl 192.168.1.254/status.htm``

  5. Some broadband routers require the use of a password when ddclient
     accesses its status page to determine the router's WAN IP address.
     If this is the case for your router, add

    fw-login=your-router-login
    fw-password=your-router-password

to the beginning of your ddclient.conf file.
Note that some routers use either 'root' or 'admin' as their login
while some others accept anything.

-------------------------------------------------------------------------------

## USING DDCLIENT WITH ppp

If you are using a ppp connection, you can easily update your DynDNS
entry with each connection, with:

    ## configure pppd to update DynDNS with each connection
    cp sample-etc_ppp_ip-up.local /etc/ppp/ip-up.local

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ppp interface.

-------------------------------------------------------------------------------

## USING DDCLIENT WITH cron

If you have not configured ddclient to use daemon-mode, you'll need to
configure cron to force an update once a month so that the dns entry will
not become stale.

    ## configure cron to force an update twice a month
    cp sample-etc_cron.d_ddclient /etc/cron.d/ddclient
    vi /etc/cron.d/ddclient

-------------------------------------------------------------------------------

## USING DDCLIENT WITH dhcpcd-1.3.17

If you are using dhcpcd-1.3.17 or thereabouts, you can easily update
your DynDNS entry automatically every time your lease is obtained
or renewed by creating an executable file named:
    ``/etc/dhcpc/dhcpcd-{your-interface}.exe``
ie.:
    ``cp sample-etc_dhcpc_dhcpcd-eth0.exe /etc/dhcpc/dhcpcd-{your-interface}.exe``

In my case, it is named dhcpcd-eth0.exe and contains the lines:

```shell
#!/bin/sh
PATH=/usr/sbin:/root/bin:${PATH}
logger -t dhcpcd IP address changed to $1
ddclient -proxy fasthttp.sympatico.ca -wildcard -ip $1 | logger -t ddclient
exit 0
```

Other DHCP clients may have another method of calling out to programs
for updating DNS entries.

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ethernet interface.

-------------------------------------------------------------------------------
## USING DDCLIENT WITH dhclient

If you are using the ISC DHCP client (dhclient), you can update
your DynDNS entry automatically every time your lease is obtained
or renewed by creating an executable file named:
    ``/etc/dhclient-exit-hooks``
ie.:
    ``cp sample-etc_dhclient-exit-hooks /etc/dhclient-exit-hooks``

Edit ``/etc/dhclient-exit-hooks`` to change any options required.

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ethernet interface.

-------------------------------------------------------------------------------
