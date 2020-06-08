# News

This document describes notable changes. For details, see the [source code
repository history](https://github.com/ddclient/ddclient/commits/master).

## Not yet released

### New features

  * Added support for OVH DynHost.

### Compatibility changes

  * Perl v5.8 or later is now required.
  * Removed the `concont` protocol. If you still use this protocol, please
    [file a bug report](https://github.com/ddclient/ddclient/issues) and we
    will restore it.
  * The `force` option no longer prevents daemonization.
  * If installed as `ddclientd` (or any other name ending in `d`), the default
    value for the `daemon` option is now 5 minutes instead of the previous 1
    minute.
  * The `pid` option is now ignored when ddclient is not daemonized.
  * ddclient now gracefully exits when interrupted by Ctrl-C.

## 2020-01-08 v3.9.1

  * added support for Yandex.Mail for Domain DNS service
  * added support for NearlyFreeSpeech.net
  * added support for DNS Made Easy
  * added systemd instructions
  * added support for dondominio.com
  * updated perl instruction
  * updated fritzbox instructions
  * fixed multidomain support for namecheap
  * fixed support for Yandex

## 2018-08-09 v3.9.0

  * new dependency: Data::Validate::IP
  * added IPv6 support for cloudfare
  * added suppport for freemyip
  * added configurable TTL to Cloudflare
  * added support for woima.fi dyndns service
  * added support for google domain

## 2015-05-28 v3.8.3

  * added Alpine Linux init script - patch sent by @Tal on github.
  * added support for nsupdate - patch sent by @droe on github
  * allow log username-password combinations - patch sent by @dirdi on github
  * adding support for cloudflare - patch sent by @roberthawdon on github
  * adding support for duckdns - patch sent by @gkranis

## 2013-12-26 v3.8.2

  * added support by ChangeIP - patch sent by Michele Giorato
  * sha-1 patch sent by pirast to allow Digest::SHA
  * allow reuse of use - patch sent by Rodrigo Araujo
  * preventing deep sleep - see [SourceForge bug
    #46](https://sourceforge.net/p/ddclient/bugs/46/)
  * Fallback to iproute if ifconfig doesn't work sent by Maccied Grela

## 2011-07-11 v3.8.1

  * Fixed [SourceForge Trac ticket
    #28](https://sourceforge.net/p/ddclient/tractickets/28/):
    FreeDNS.afraid.org changed api slightly
  * Added dtdns-support
  * Added support for longer password
  * Added cisco-asa patch
  * Added support for LoopiaDNS

## Older Releases

See the source code repository history.
