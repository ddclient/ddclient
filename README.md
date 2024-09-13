# DDCLIENT

`ddclient` is a Perl client used to update dynamic DNS entries for accounts
on many dynamic DNS services. It uses `curl` for internet access.

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
  * [DDNS.fm](https://www.ddns.fm/)
  * [DigitalOcean](https://www.digitalocean.com/)
  * [dinahosting](https://dinahosting.com)
  * [Directnic](https://directnic.com)
  * [DonDominio](https://www.dondominio.com)
  * [DNS Made Easy](https://dnsmadeeasy.com)
  * [DNSExit](https://dnsexit.com/dns/dns-api)
  * [dnsHome.de](https://www.dnshome.de)
  * [Domeneshop](https://api.domeneshop.no/docs/#tag/ddns/paths/~1dyndns~1update/get)
  * [DslReports](https://www.dslreports.com)
  * [Duck DNS](https://duckdns.org)
  * [DynDNS.com](https://account.dyn.com)
  * [EasyDNS](https://www.easydns.com )
  * [Enom](https://www.enom.com)
  * [Freedns](https://freedns.afraid.org)
  * [Freemyip](https://freemyip.com)
  * [Gandi](https://gandi.net)
  * [GoDaddy](https://www.godaddy.com)
  * [Hurricane Electric](https://dns.he.net)
  * [Ionos](https://ionos.com)
  * [Infomaniak](https://faq.infomaniak.com/2376)
  * [INWX](https://www.inwx.com/)
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
operating system. See the image to the right for a list of distributions with a ddclient package.

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

## Known issues
This is a list for quick referencing of known issues. For further details check out the linked issues and the changelog.

Note that any issues prior to version v3.9.1 will not be listed here.
If a fix is committed but not yet part of any tagged release, the notes here will reference the not-yet-released version number.

### v3.11.2 - v3.9.1: SSL parameter breaks HTTP-only IP acquisition

The `ssl` parameter forces all connections to use HTTPS.  While technically
working as expected, this behavior keeps coming up as a pain point when using
HTTP-only IP querying sites such as http://checkip.dyndns.org.  Starting with
v4.0.0, the behavior is changed to respect `http://` in a URL.  A separate
parameter to disallow all HTTP connections or warn about them may be added
later.

**Fix**: v4.0.0 uses HTTP to connect to URLs starting with `http://`.  See
[here](https://github.com/ddclient/ddclient/pull/608) for more info.

**Workaround**: Disable the SSL parameter

### v3.10.0: Chunked encoding not corretly supported in IO::Socket HTTP code
Using the IO::Socket HTTP code will break in various ways whenever the server responds using HTTP 1.1 chunked encoding. Refer to [this issue](https://github.com/ddclient/ddclient/issues/548) for more info.

**Fix**: v3.11.0 - IO::Socket has been deprecated there and curl has been made the standard.

**Workaround**: Use curl for transfers by either setting `-curl` in the command line or by adding `curl=yes` in the config

### v3.10.0: Spammed updates to some providers
This issue arises when using the `use` parameter in the config and using one of these providers:
- Cloudflare
- Hetzner
- Digitalocean
- Infomaniak

**Fix**: v3.11.2

**Workaround**: Use the `usev4`/`usev6` parameters instead of `use`.


## TROUBLESHOOTING

  * Enable debugging and verbose messages: `ddclient --daemon=0 --debug --verbose`

  * Do you need to specify a proxy?
    If so, just add a `proxy=your.isp.proxy` to the `ddclient.conf` file.

  * Define the IP address of your router with `fwv4=xxx.xxx.xxx.xxx` in
    `/etc/ddclient/ddclient.conf` and then try `$ ddclient --daemon=0 --query`
    to see if the router status web page can be understood.

  * Need support for another router/firewall?
    Define the router yourself with:

    ```
    usev4=fwv4
    fwv4=url-to-your-router-status-page
    fwv4-skip="regular expression matching any string preceding your IP address, if necessary"
    ```

    ddclient does something like this to provide builtin support for common
    routers.
    For example, the Linksys routers could have been added with:

    ```
    usev4=fwv4
    fwv4=192.168.1.1/Status.htm
    fwv4-skip=WAN.*?IP Address
    ```

    OR [create a new issue](https://github.com/ddclient/ddclient/issues/new)
    containing the output from:

    ```
    curl --include --location http://url.of.your.firewall/ip-status-page
    ```

    so that we can add a new firewall definition to a future release of
    ddclient.

  * Some broadband routers require the use of a password when ddclient accesses
    its status page to determine the router's WAN IP address.
    If this is the case for your router, add

    ```
    fw-login=your-router-login
    fw-password=your-router-password
    ```

    to the beginning of your ddclient.conf file.
    Note that some routers use either 'root' or 'admin' as their login while
    some others accept anything.

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
ddclient --proxy fasthttp.sympatico.ca --wildcard --ip $1 | logger -t ddclient
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
