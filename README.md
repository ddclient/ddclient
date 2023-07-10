# DDCLIENT

`ddclient` is a Perl client used to update dynamic DNS entries for accounts 
on many dynamic DNS services. It uses `curl` for internet access.

This is a friendly fork/continuation of https://github.com/ddclient/ddclient

## Alternatives

You might also want to consider using one of the following, if they support
your dynamic DNS provider(s): <https://github.com/troglobit/inadyn> or
<https://github.com/lopsided98/dnsupdate>.

## Supported services

Dynamic DNS services currently supported include:

* [1984.is](https://www.1984.is/product/freedns)
* [ChangeIP](https://www.changeip.com)
* [CloudFlare](https://www.cloudflare.com)
* [ClouDNS](https://www.cloudns.net)
* [dinahosting](https://dinahosting.com)
* [DonDominio](https://www.dondominio.com)
* [DNS Made Easy](https://dnsmadeeasy.com)
* [DNSExit](https://dnsexit.com/dns/dns-api)
* [domenehsop](https://api.domeneshop.no/docs/#tag/ddns/paths/~1dyndns~1update/get)
* [DslReports](https://www.dslreports.com)
* [Duck DNS](https://duckdns.org)
* [DynDNS.com](https://account.dyn.com)
* [EasyDNS](https://www.easydns.com )
* [Enom](https://www.enom.com)
* [Freedns](https://freedns.afraid.org)
* [Freemyip](https://freemyip.com)
* [Gandi](https://gandi.net)
* [GoDaddy](https://www.godaddy.com)
* [Google](https://domains.google)
* [Infomaniak](https://faq.infomaniak.com/2376)
* [Loopia](https://www.loopia.se)
* [Mythic Beasts](https://www.mythic-beasts.com/support/api/dnsv2/dynamic-dns)
* [NameCheap](https://www.namecheap.com)
* [NearlyFreeSpeech.net](https://www.nearlyfreespeech.net/services/dns)
* [Njalla](https://njal.la/docs/ddns)
* [Noip](https://www.noip.com)
* nsupdate - see nsupdate(1) and ddns-confgen(8)
* [OVH](https://www.ovhcloud.com)
* [Porkbun](https://porkbun.com)
* [regfish.de](https://www.regfish.de/domains/dyndns)
* [Sitelutions](https://www.sitelutions.com)
* [woima.fi](https://woima.fi)
* [Yandex](https://dns.yandex.com)
* [Zoneedit](https://www.zoneedit.com)

`ddclient` supports finding your IP address from many cable and DSL
broadband routers.

Comments, suggestions and requests: please file an issue at
https://github.com/ddclient/ddclient/issues/new

The code was originally written by Paul Burry and is now hosted and
maintained through github.com. Please check out https://ddclient.net

## REQUIREMENTS

  * An account from a supported dynamic DNS service provider
  * Perl v5.10.1 or later
      * `JSON::PP` perl library for JSON support
  * Linux, macOS, or any other Unix-ish system
  * An implementation of `make` (such as [GNU
    Make](https://www.gnu.org/software/make/))
  * If you are installing from a clone of the Git repository, you will
    also need [GNU Autoconf](https://www.gnu.org/software/autoconf/)
    and [GNU Automake](https://www.gnu.org/software/automake/).

## DOWNLOAD

See https://github.com/ddclient/ddclient/releases

## INSTALLATION

### Distribution Package

<a href="https://repology.org/project/ddclient/versions">
  <img src="https://repology.org/badge/vertical-allrepos/ddclient.svg" alt="Packaging status" align="right">
</a>
The easiest way to install ddclient is to install a package offered by your
operating system. See the image to the right for a list of distributions with a
ddclient package.

### Manual Installation

  1. Extract the distribution tarball (`.tar.gz` file) and `cd` into
     the directory:

     ```shell
     tar xvfa ddclient-3.XX.X.tar.gz
     cd ddclient-3.XX.X
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

#### systemd

    cp sample-etc_systemd.service /etc/systemd/system/ddclient.service

enable automatic startup when booting

    systemctl enable ddclient.service

start the first time by hand

    systemctl start ddclient.service

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

## USING DDCLIENT WITH `ppp`

If you are using a ppp connection, you can easily update your DynDNS
entry with each connection, with:

    ## configure pppd to update DynDNS with each connection
    cp sample-etc_ppp_ip-up.local /etc/ppp/ip-up.local

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ppp interface.

## USING DDCLIENT WITH `cron`

If you have not configured ddclient to use daemon-mode, you'll need to
configure cron to force an update once a month so that the dns entry will
not become stale.

    ## configure cron to force an update twice a month
    cp sample-etc_cron.d_ddclient /etc/cron.d/ddclient
    vi /etc/cron.d/ddclient

## USING DDCLIENT WITH `dhcpcd`

If you are using dhcpcd-1.3.17 or thereabouts, you can easily update
your DynDNS entry automatically every time your lease is obtained
or renewed by creating an executable file named:
    ``/etc/dhcpc/dhcpcd-{your-interface}.exe``
ie.:
    ``cp sample-etc_dhcpc_dhcpcd-eth0.exe /etc/dhcpc/dhcpcd-{your-interface}.exe``

In my case, it is named dhcpcd-eth0.exe and contains the lines:

```shell
#!/bin/sh
PATH=/usr/bin:/root/bin:${PATH}
logger -t dhcpcd IP address changed to $1
ddclient -proxy fasthttp.sympatico.ca -wildcard -ip $1 | logger -t ddclient
exit 0
```

Other DHCP clients may have another method of calling out to programs
for updating DNS entries.

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ethernet interface.

## USING DDCLIENT WITH `dhclient`

If you are using the ISC DHCP client (dhclient), you can update
your DynDNS entry automatically every time your lease is obtained
or renewed by creating an executable file named:
    ``/etc/dhclient-exit-hooks``
ie.:
    ``cp sample-etc_dhclient-exit-hooks /etc/dhclient-exit-hooks``

Edit ``/etc/dhclient-exit-hooks`` to change any options required.

Alternatively, you may just configure ddclient to operate as a daemon
and monitor your ethernet interface.
