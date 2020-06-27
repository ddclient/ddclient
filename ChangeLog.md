# ChangeLog

This document describes notable changes. For details, see the [source code
repository history](https://github.com/ddclient/ddclient/commits/master).

## Not yet released

### New features

  * Added support for OVH DynHost.

### Bug fixes

  * Fixed a regression introduced in v3.9.0 that caused
    `use=ip,ip=<ipv4-address>` to fail.
  * "true" is now accepted as a boolean value.

### Compatibility and dependency changes

  * Perl v5.10.1 or later is now required.
  * Removed dependency on Data::Validate::IP.
  * When `use=if`, iproute2's `ip` command is now attempted before falling back
    to `ifconfig` (it used to be the other way around). If you set `if-skip`,
    please check that your configuration still works as expected.
  * Removed the `concont` protocol. If you still use this protocol, please
    [file a bug report](https://github.com/ddclient/ddclient/issues) and we
    will restore it.
  * The `force` option no longer prevents daemonization.
  * If installed as `ddclientd` (or any other name ending in `d`), the default
    value for the `daemon` option is now 5 minutes instead of the previous 1
    minute.
  * The `pid` option is now ignored when ddclient is not daemonized.
  * ddclient now gracefully exits when interrupted by Ctrl-C.
  * The way ddclient chooses the default for the `use` option has changed.
    Rather than rely on the default, users should explicitly set the `use`
    option.
  * The `fw-banlocal` option is deprecated and no longer does anything.

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

### Detailed list of changes

  * [r208] wimpunk: ddclient: cosmetic, remove stray space indent
  * [r207] wimpunk: ddclient: Support IPv6 for CloudFlare
  * [r206] wimpunk: ddclient: name cheap support https now

    From name cheap it seems http is supported now.  Since the password was
    send on plaintext, https should be used
  * [r205] wimpunk: ddclient: Use JSON::PP instead of the (deprecated)
    JSON::Any
  * [r204] wimpunk: ddclient: Follow expected behavior

    Align ddclient behavior and documentation with namecheap's -
    https://www.namecheap.com/support/knowledgebase/article.aspx/583/11/how-do-i-configure-ddclient
  * [r203] wimpunk: ddclient: Specify port number properly to 'nsupdate' (#58)

    If a port number is included in the 'server' configuration item, ddclient
    allows a port number to be specified by appending a colon and the port
    number to the server's name or IPv4 address.  However, nsupdate does not
    support this syntax, it requires the port number to be separated from the
    server name/address by whitespace.

    Signed-off-by: Kevin P. Fleming <kevin@km6g.us>
  * [r202] wimpunk: README.md, README.ssl, ddclient, sample-etc_ddclient.conf,
    sample-etc_rc.d_init.d_ddclient.alpine: Adding support for freemyip.com

    Support provided by @Cadence-GitHub in by pull request #47
  * [r195] wimpunk: ddclient, sample-etc_ddclient.conf: Merge pull request #25
    from dancapper/master

    Adding configurable TTL to Cloudflare

    This change adds configurable TTL to cloudflare instead of just using
    hardcoded value of 1 which sets "automatic" TTL any time ddclient updates
    the IP address.
  * [r194] wimpunk: sample-etc_ddclient.conf: Merge pull request #24 from
    gkranis/master

    Adding duckdns example

    Duckdns example added to sample-etc_ddclient.conf
  * [r193] wimpunk: README.md, sample-etc_rc.d_init.d_ddclient.ubuntu: Prevent
    service to start multiple times.  Added messages if trying to start/stop
    already started/stopped service.  Added daemon install instructions for
    ubuntu.
  * [r192] wimpunk: ddclient: odd-fw-patch-squashed
  * [r191] wimpunk: README.md, ddclient: Added support for woima.fi dyndns
    service
  * [r190] wimpunk: ddclient: Cleanup: removing revision info.

    Removing revision info even when it's just in the comments.
  * [r189] wimpunk: ChangeLog: Adding ChangeLog

    Since we are not going to fetch the changes from svn anymore, we add the
    old ChangeLog again.
  * [r188] wimpunk: .cvsignore, .gitignore: Cleanup: removing old ignore files

    Switching to git so we don't need .cvsignore anymore
  * [r187] wimpunk: COPYING: FSF address

    Address for FSF was wrong, corrected
  * [r186] wimpunk: Changelog.old, README.cisco, ddclient,
    sample-etc_cron.d_ddclient, sample-etc_ddclient.conf,
    sample-etc_dhclient-exit-hooks, sample-etc_dhcpc_dhcpcd-eth0.exe,
    sample-etc_ppp_ip-up.local, sample-etc_rc.d_init.d_ddclient.lsb,
    sample-etc_rc.d_init.d_ddclient.redhat: Cleanup: removing Id tags from the
    files

    Preparing a complete move to git. The Id tag isn't useful so removing from
    the files seemed to be the best solotion

## 2015-05-28 v3.8.3

  * added Alpine Linux init script - patch sent by @Tal on github.
  * added support for nsupdate - patch sent by @droe on github
  * allow log username-password combinations - patch sent by @dirdi on github
  * adding support for cloudflare - patch sent by @roberthawdon on github
  * adding support for duckdns - patch sent by @gkranis

### Detailed list of changes

  * [r183] wimpunk: ., release: Removing unneeded release directory
  * [r182] wimpunk: ddclient: Reverting to the old perl requirements like
    suggested in #75

    The new requirements were added when adding support for cloudflare. By the
    simple fix suggested by Roy Tam we could revert the requirements which make
    ddclient back usable on CentOS and RHEL.
  * [r181] wimpunk: ddclient: ddclient: made json optional

    As suggested in pull 7 on github by @abelbeck and @Bugsbane it is better to
    make the use of JSON related to the use of cloudflare.
  * [r180] wimpunk: ddclient: ddclient: reindenting cloudflare

    Indenting cloudflare according to the vim tags
  * [r179] wimpunk: ddclient: ddclient: correction after duckdns merge

    Correcting duckdns configuration after commit r178
  * [r178] wimpunk: ddclient: Added simple support for Duckdns www.duckdns.org

    Patch provided by gkranis on github.  Merge branch 'gkranis'
  * [r177] wimpunk: README.md: Added duckDNS to the README.md
  * [r176] wimpunk: sample-etc_rc.d_init.d_ddclient.ubuntu: update ubuntu
    init.d script

    Merge pull request #9 from gottaloveit/master
  * [r175] wimpunk: Changelog, Changelog.old: Renamed Changelog to
    Changelog.old

    Avoiding conflicts on case insensitive filesystems
  * [r174] wimpunk: ddclient: Add missing config line for CloudFlare

    Merge pull request #19 from shikasta-net/fixes
  * [r173] wimpunk: ddclient: Merge pull request #22 from reddyr/patch-1

    loopia.se changed the "Current Address:" output string to "Current IP
    Address:"
  * [r172] wimpunk: ddclient: fixed missing ) for cloudflare service hash

    Merge pull request #16 from adepretis/master
  * [r171] wimpunk: README.md, ddclient, sample-etc_ddclient.conf: Adding
    support for google domain

    Patch gently provided through github on
    https://github.com/wimpunk/ddclient/pull/13
  * [r170] wimpunk: README.md, ddclient, sample-etc_ddclient.conf: Added
    support for Cloudflare and multi domain support for namecheap

    Pull request #7 from @roberthawdon See
    https://github.com/wimpunk/ddclient/pull/7 for more info.
  * [r169] wimpunk: ddclient: Bugfix: allowing long username-password
    combinations

    Patch provided by @dirdi through github.
  * [r166] wimpunk: ddclient: Fixing bug #72: Account info revealed during noip
    update
  * [r165] wimpunk: ddclient: Interfaces can be named almost anything on modern
    systems.

    Patch provided by Stephen Couchman through github
  * [r164] wimpunk: ddclient: Only delete A RR, not any RR for the FQDN

    Make the delete command specific to A RRs. This prevents ddclient from
    deleting other RRs unrelated to the dynamic address, but on the same
    FQDN. This can be specifically a problem with KEY RRs when using SIG(0)
    instead of symmetric keys.

    Reported by: Wellie Chao Bug report:
    http://sourceforge.net/p/ddclient/bugs/71/

    Fixes #71
  * [r163] wimpunk: README.md, ddclient: Adding support for nsupdate.

    Patch provided by Daniel Roethlisberger <daniel@roe.ch> through github.
  * [r162] wimpunk: README.md, README.ssl, ddclient: Removed revision
    information

    Revision information isn't very usable when switching to git.
  * [r161] wimpunk: README.md, README.ssl, ddclient,
    sample-etc_rc.d_init.d_ddclient.alpine: Added Alpine Linux init script

    Patch send by Tal on github.
  * [r160] wimpunk: RELEASENOTE: Corrected release note
  * [r159] wimpunk: release/readme.txt: Commiting updated release information
  * [r158] wimpunk: README.md, RELEASENOTE: Committing release notes and readme
    information to trunk

## 2013-12-26 v3.8.2

  * added support by ChangeIP - patch sent by Michele Giorato
  * sha-1 patch sent by pirast to allow Digest::SHA
  * allow reuse of use - patch sent by Rodrigo Araujo
  * preventing deep sleep - see [SourceForge bug
    #46](https://sourceforge.net/p/ddclient/bugs/46/)
  * Fallback to iproute if ifconfig doesn't work sent by Maccied Grela

### Detailed list of changes

  * [r156] wimpunk: patches: Moving patching to the root of the repository.

    The patches are mostly there for historical reasons. They've been moved
    away to make cleaning easier. I think the applied patches should even be
    removed.
  * [r155] wimpunk: ddclient: Fallback to iproute if ifconfig doesn't work.

    This fix applies the patch provided by Maccied Grela in [bugs:#26]
  * [r154] wimpunk: ddclient: preventing deep sleep - see [bugs:#46]

    Fixing [bugs:#46] by applying the provided patch.
  * [r153] wimpunk: ddclient: Applying patch from [fb1ad014] fixing bug [#14]

    More info can be found on [fb1ad014] and has been discussed in the
    mailinglist:
    http://article.gmane.org/gmane.network.dns.ddclient.user/71. The patch was
    send by Rodrigo Araujo.
  * [r152] wimpunk: ddclient: Adding sha1-patch provided by pirast in
    [9742ac09]
  * [r150] wimpunk: README.md, ddclient, sample-etc_ddclient.conf: Adding
    support for ChangeIP based on the patch from Michele Giorato
    http://sourceforge.net/p/ddclient/discussion/399428/thread/e85661ad/
  * [r148] wimpunk: README.md: Updated README file
  * [r147] wimpunk: ., README, README.md: Applying markdown syntax to README

## 2011-07-11 v3.8.1

  * Fixed [SourceForge Trac ticket
    #28](https://sourceforge.net/p/ddclient/tractickets/28/):
    FreeDNS.afraid.org changed api slightly
  * Added dtdns-support
  * Added support for longer password
  * Added cisco-asa patch
  * Added support for LoopiaDNS

### Detailed list of changes

  * [r131] wimpunk: release/readme.txt: Updates after releasing 3.8.1
  * [r129] wimpunk: release/readme.txt: Corrected release/readme.txt
  * [r128] wimpunk: sample-etc_ppp_ip-up.local: Applied ip-up_run-parts.diff
    from ubuntu
  * [r127] wimpunk: ddclient: Applied smc-barricade-fw-alt.diff from ubuntu
  * [r126] wimpunk: ddclient: Fixing #28: FreeDNS.afraid.org changed api
    slightly
  * [r125] wimpunk: ddclient, sample-etc_ddclient.conf: Added patch for
    dtdns-support (#39)
  * [r124] wimpunk: ddclient: Patching with nic_updateable-warning patch
    provided by antespi in ticket #2
  * [r123] wimpunk: ddclient: Patching with zoneedit patch provided by
    killer-jk in ticket #15
  * [r122] wimpunk: ddclient: Added longer password support, sended by Ingo
    Schwarze (#3130634)
  * [r121] wimpunk: ddclient: Fixing bug #13: multiple fetch-ip but introducing
    a multiple ip bug
  * [r120] wimpunk: ddclient: patch for #10: invalid value for keyword ip
  * [r119] wimpunk: ddclient: Applied patch from ticket #8, patch for cache
    content leaks to global
  * [r118] wimpunk: ddclient: Applied patch from ticket #7, provided by Chris
    Carr
  * [r117] wimpunk: ddclient: Fixed #6: Add Red Hat package name to Perl module
    IO::Socket::SSL error message
  * [r116] wimpunk: ddclient: Subversion revision added
  * [r115] wimpunk: ddclient, patches/cisco-asa.patch: Added cisco-asa patch
    (2891001) submitted by Philip Gladstone
  * [r114] wimpunk: ddclient, patches/prevent-hang.patch: Added prevent-hang
    patch (2880462) submitted by Panos
  * [r113] wimpunk: ddclient, patches/foreground.patch: Added foreground patch
    (1893144) submitted by John Palkovic
  * [r112] wimpunk: README, ddclient, patches/loopia.patch,
    sample-etc_ddclient.conf: #1609799 Support for LoopiaDNS (submitted by
    scilence)
  * [r111] wimpunk: ddclient, patches/freedns-patch: applied freedns patch
    (patch 2832129)
  * [r110] wimpunk: ddclient: Bug 2792436: fixed abuse message of dyndns
  * [r109] wimpunk: sample-etc_ddclient.conf: Added warning about the update
    interval (#2619505)
  * [r108] wimpunk: .cvsignore, RELEASENOTE, ddclient, release,
    release/readme.txt: Modified during the release of ddclient-3.8.0

## 2009-01-27 v3.8.0

### Detailed list of changes

  * [r106] wimpunk: ddclient: help about postscript added
  * [r105] wimpunk: ddclient, patches/password.patch: Added better password
    handling sended by Ingo Schwarze
  * [r104] wimpunk: TODO, sample-ddclient-wrapper.sh: Added ddclient wrapper
    script
  * [r103] wimpunk: ddclient: Extra fix for multiple IP's
  * [r102] wimpunk: sample-etc_ddclient.conf: Added some remarks concerning the
    postscript. See https://sourceforge.net/forum/message.php?msg_id=5550545
  * [r101] wimpunk: ddclient, patches/multiple-ip.patch: Added support for
    multiple IP adresses. See
    http://permalink.gmane.org/gmane.network.dns.ddclient.user/17
  * [r100] wimpunk: patches/namecheap.patch: extra comments added to namecheap
    patch
  * [r99] wimpunk: patches/namecheap.patch: namecheap patch added to patches
    section
  * [r98] wimpunk: .: New trunk created based on the old trunk/svn
  * [r96] wimpunk: svn: Moved old trunk/svn to ddclient and it will be the new
    trunk
  * [r95] wimpunk: svn: Ignoring test configuration
  * [r94] wimpunk: svn/.cvsignore, svn/RELEASENOTE, svn/UPGRADE: Added some
    release related files
  * [r93] wimpunk: svn/patches/no-host.patch: Added not used no-host patch to
    patches section
  * [r90] wimpunk: svn/ddclient: Added more info about the daemon interval
  * [r89] wimpunk: svn/ddclient: Preventing error while reading cache when ip
    wasn't set correctly before
  * [r88] wimpunk: svn/ddclient: Preventing an error when trying to send a
    message on mail-failure
  * [r87] wimpunk: svn/ddclient, svn/sample-etc_ddclient.conf: Modified
    documentation about zoneedit based on the comments from Oren Held
  * [r86] wimpunk: svn/patches/ddclient.daemon-timeout.patch: Added patch which
    was applied to rev 27 (posted by James deBoer)
  * [r85] wimpunk: svn/patches/eurodns.patch: Patch modified to apply on
    ddclient 3.7.3
  * [r84] wimpunk: svn/patches/mail-on-kill.patch: Added mail-on-kill patch to
    patches section
  * [r83] wimpunk: svn/ddclient: Sending mail when killed, not after
    TERM-signal
  * [r82] wimpunk: svn/README: Added creation of cache dir
  * [r81] wimpunk: svn/ddclient, svn/patches/ubuntu/default-timeout.patch:
    Added and applied default timeout patch from
    https://bugs.launchpad.net/ubuntu/+source/ddclient/+bug/116066
  * [r80] wimpunk: svn/ddclient, svn/patches/ddclient-noip.patch: Added
    ddclient-noip.patch send by Kurt Bussche.

## 2007-08-07 v3.7.3

  * Changelog moved to more correct ChangeLog generated by `svn2cl
    --group-by-day -i`. See http://tinyurl.com/2fzhc6

### Detailed list of changes

  * [r78] wimpunk: svn/ddclient: Updated version number to 3.7.3
  * [r77] wimpunk: svn/ddclient, svn/patches/typo_dnspark.patch: Applied
    typo_dnspark.patch send by Marco
  * [r76] wimpunk: svn/README.ssl: Renamed dyndns.org to dyndns.com
  * [r75] wimpunk: svn/README: Removed ^M at line 37
  * [r74] wimpunk: svn/ddclient: Removed line 183, comments on Vigor 2200 USB
  * [r73] wimpunk: svn: Ignoring ChangeLog since autogenerated
  * [r72] wimpunk: svn/Changelog: Notification about changed ChangeLog
    configuration
  * [r71] wimpunk: svn/patches/ubuntu/dyndns_com.diff: Removed patch since it's
    invalid
  * [r70] wimpunk: svn/patches/opendns.patch: Added not applied opendns.patch,
    see tracker #1758564
  * [r69] wimpunk: svn/patches/debianpatches,
    svn/patches/debianpatches/abuse_msg.diff,
    svn/patches/debianpatches/cachedir.diff,
    svn/patches/debianpatches/cisco_fw.diff,
    svn/patches/debianpatches/config_path.diff,
    svn/patches/debianpatches/daemon_check.diff,
    svn/patches/debianpatches/daemon_interval.diff,
    svn/patches/debianpatches/help_nonroot(2).diff,
    svn/patches/debianpatches/help_nonroot.diff,
    svn/patches/debianpatches/ip-up_run-parts.diff,
    svn/patches/debianpatches/maxinterval.diff,
    svn/patches/debianpatches/readme.txt,
    svn/patches/debianpatches/sample_path.diff,
    svn/patches/debianpatches/smc-barricade-7401bra.patch,
    svn/patches/debianpatches/smc-barricade-fw-alt.diff,
    svn/patches/debianpatches/update-new-config.patch, svn/patches/ubuntu,
    svn/patches/ubuntu/checked_ssl_load.diff,
    svn/patches/ubuntu/config_path.diff,
    svn/patches/ubuntu/daemon_interval.diff,
    svn/patches/ubuntu/dyndns_com.diff, svn/patches/ubuntu/sample_ubuntu.diff,
    svn/patches/ubuntu/series, svn/patches/ubuntu/smc-barricade-fw-alt.diff:
    Added debian and ubuntu patches
  * [r68] wimpunk: svn/TODO: Added url to feature request dyndns
  * [r67] wimpunk: svn/README, svn/patches/readme.patch: Run dos2unix on readme
    and it's patch which Marco Rodrigues submitted.
  * [r66] wimpunk: svn/README, svn/patches/readme.patch: Partial applied
    readme.patch. See tracker #1752931
  * [r65] wimpunk: svn/ddclient: signature modified
  * [r64] wimpunk: svn/ddclient: Added website to ddclient comments
  * [r63] wimpunk: svn/patches/regex_vlan.patch: Added extra comments to the
    patch.
  * [r62] wimpunk: svn/ddclient, svn/patches/create_patch.sh,
    svn/patches/regex_vlan.patch, svn/patches/typo_namecheap_patch.diff.new:
    Added patches and applied regex_vlan.patch. See bug #1747337
  * [r61] wimpunk: svn/ddclient: Applied typo_namecheap_patch.diff send by
    Marco Rodrigues
  * [r60] wimpunk: svn/sample-etc_ppp_ip-up.local: Reverted the patch from
    torsten. See [ 1749470 ] Bug in Script sample-etc_ppp_ip-up.local
  * [r59] wimpunk: svn/release, svn/release/readme.txt: Adding some release
    documentation

## 2007-06-14 v3.7.2

  * Preventing unitialized values, check
    https://sourceforge.net/forum/message.php?msg_id=4167772
  * added a TODO list
  * Removed the two empty lines at the end of ddclient
  * Applied checked_ssl_load.diff from Ubuntu
  * Cosmetic change about checkip
  * Changed nic_namecheap_update following the suggestion of edmdude on the
    forum (https://sourceforge.net/forum/message.php?msg_id=4316938)
  * Applied easydns.patch
  * 3com-oc-remote812 patch by The_Beast via IRC.
  * Applied eurodns.patch

### Detailed list of changes

  * [r57] wimpunk: svn/Changelog, svn/ddclient: Changed version number
  * [r55] wimpunk: svn/patches, svn/patches/3com-oc-remote812.patch,
    svn/patches/easydns.patch, svn/patches/eurodns.patch: Patches directory
    added
  * [r54] wimpunk: svn/ddclient: 3com-oc-remote812 patch by The_Beast via IRC:
    see patches/3com-oc-remote812.patch
  * [r53] wimpunk: svn/ddclient: Applied easydns.patch, patch 117054
  * [r52] wimpunk: svn/ddclient: Changed nic_namecheap_update following the
    suggestion of edmdude on the forum
    (https://sourceforge.net/forum/message.php?msg_id=4316938)
  * [r48] wimpunk: svn/ddclient: Cosmetic change about checkip
  * [r47] wimpunk: svn/ddclient: Applied checked_ssl_load.diff from ubuntu
  * [r46] wimpunk: svn/ddclient: Removed the two empty lines at the end of
    ddclient
  * [r44] wimpunk: svn/TODO: added a TODO list
  * [r43] wimpunk: svn/Changelog, svn/ddclient: Preventing unitialized values,
    check https://sourceforge.net/forum/message.php?msg_id=4167772

## 2007-01-25 v3.7.1

  * URL of zoneedit has changed (see bug #1558483)
  * Added initscript for Ubuntu (posted by Paolo Martinelli)
  * Added patch "Patch: Treat --daemon values as intervals" (submitted by James
    deBoer)
  * Don't send any mail when in not running daemon mode (patch submitted by
    Daniel Thaler)
  * Changed Changelog syntax
  * Applied patches submitted by Torsten:
      * abuse_msg.diff: ddclient still reports the email to contact dyndns.org
        but they prefer a web form today (IIRC). This patch adjusts the abuse
        warning printed by ddclient.
      * cachedir.diff: Original ddclient stores a cache file in /etc which
        would belong in /var/cache in my opinion and according to the FHS.
      * help_nonroot.diff: Allow calling the help function as non-root.
      * update-new-config.patch: Force update if config has changed
      * smc-barricade-7401bra.patch: Support for SMC Barricade 7401BRA FW
        firewall
      * cisco_fw.diff: Use configured hostname for firewall access with
        -use=cisco (closes: #345712). Thanks to Per Carlson for the patch!  See
        http://bugs.debian.org/345712.
      * maxinterval.diff: Increase max interval for updates.  See
        http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=129370
        http://www.dyndns.com/support/services/dyndns/faq.html#q15
  * Changed max-interval to 25days.  See
    https://www.dyndns.com/services/dns/dyndns/faq.html

### Detailed list of changes

  * [r40] wimpunk: svn/Changelog, svn/ddclient: Changed max-interval to
    25days. See https://www.dyndns.com/services/dns/dyndns/faq.html
  * [r39] wimpunk: svn/Changelog, svn/ddclient: Applied maxinterval.diff:
    Increase max interval for updates.  See
    http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=129370
    http://www.dyndns.com/support/services/dyndns/faq.html#q15
  * [r38] wimpunk: svn/ddclient: Applied cisco_fw.diff: Use configured hostname
    for firewall access with -use=cisco (closes: #345712). Thanks to Per
    Carlson for the patch!  See http://bugs.debian.org/345712.
  * [r37] wimpunk: svn/Changelog, svn/ddclient: Applied
    smc-barricade-7401bra.patch: Support for SMC Barricade 7401BRA FW firewall
    (submitted by Torsten) Changelog modified for all previous patches from
    Torsten
  * [r36] wimpunk: svn/ddclient: Applied update-new-config.patch: Force update
    if config has changed (submitted by Torsten)
  * [r35] wimpunk: svn/sample-etc_ppp_ip-up.local: Applied
    ip-up_run-parts.diff: Fix parameter in ip-up script.  (submitted by
    Torsten)
  * [r34] wimpunk: svn/ddclient: Applied help_nonroot.diff: Allow calling the
    help function as non-root.  (submitted by Torsten)
  * [r33] wimpunk: svn/ddclient: Applied cachedir.diff: Original ddclient
    stores a cache file in /etc which would belong in /var/cache in my opinion
    and according to the FHS. Patch changes that. (submitted by Torsten)
  * [r32] wimpunk: svn/ddclient: Applied abuse_msg.diff: ddclient still reports
    the email to contact dyndns.org but they prefer a web form today
    (IIRC). This patch adjusts the abuse warning printed by
    ddclient. (submitted by Torsten)
  * [r31] wimpunk: svn/Changelog: Changed Changelog syntax
  * [r30] wimpunk: svn/Changelog, svn/ddclient: Don't send any mail when in not
    running daemon mode (patch submitted by Daniel Thaler)
  * [r28] wimpunk: svn/Changelog, svn/ddclient: Added patch "Patch: Treat
    --daemon values as intervals" (submitted by James deBoer)
  * [r22] wimpunk: svn/Changelog, svn/sample-etc_rc.d_init.d_ddclient.ubuntu:
    Added initscript for Ubuntu (posted by Paolo Martinelli)
  * [r21] wimpunk: svn/Changelog, svn/ddclient: URL of zoneedit has changed
    (see bug #1558483)

## 2006-06-14 v3.7.0

  * Added vi tag
  * Added support for 2Wire 1701HG Gateway (see
    https://sourceforge.net/forum/message.php?msg_id=3496041 submitted by hemo)
  * added ssl-support by perlhaq
  * updated cvs version to 3.7.0-pre
  * added support for Linksys RV042, see feature requests #1501093, #1500877
  * added support for netgear-rp614, see feature request #1237039
  * added support for watchguard-edge-x, patch #1468981
  * added support for dlink-524, see patch #1314272
  * added support for rtp300
  * added support for netgear-wpn824
  * added support for linksys-wcg200, see patch #1280713
  * added support for netgear-dg834g, see patch #1176425
  * added support for netgear-wgt624, see patch #1165209
  * added support for sveasoft, see patch #1102432
  * added support for smc-barricade-7004vbr, see patch #1087989
  * added support for sitecom-dc202, see patch #1060119
  * fixed the error of stripping out '#' in the middle of password, bug
    #1465932
  * fixed a couple bugs in sample-etc_rc.d_init.d_ddclient and added some extra
    auto distro detection
  * added the validation of values when reading the configuration value.
  * this fixes a bug when trying to use periods/intervals in the daemon check
    times, bug #1209743
  * added timeout option to the IO::Socket call for timing out the initial
    connection, bug: #1085110

### Detailed list of changes

  * [r11] wimpunk: svn/Changelog, svn/ddclient: Changed version number
  * [r8] wimpunk: ., html, svn, xml: Created trunk and tags, moved directories
    to it
  * [r6] wimpunk: Changed the order of perl and update of README.ssl
  * [r5] ddfisher: see Changelog
  * [r4] ddfisher: updated changelog
  * [r3] ddfisher: See Changelog
  * [r2] wimpunk: Reorganise

## v3.6.7

  * modified sample-etc_rc.d_init.d_ddclient.lsb (bug #1231930)
  * support for ConCont Protocol (patch #1265128) submitted by seather_misery
  * problem with sending mail should be solved
  * corrected a few writing mistakes
  * support for 'NetComm NB3' adsl modem (submitted by crazyprog)
  * Added Sitelutions DynDNS, fixed minor Namecheap bug (patch #1346867)

## v3.6.6

  * support for olitec-SX200
  * added sample-etc_rc.d_init.d_ddclient.lsb as a sample script for
    lsb-compliant systems.
  * support for linksys wrt854g (thanks to Nick Triantos)
  * support for linksys ver 3
  * support for Thomson (Alcatel) SpeedTouch 510 (thanks to Aldoir)
  * Cosmetic fixes submitted by John Owens

## v3.6.5

  * there was a bug in the linksys-ver2
  * support for postscript (thanks to Larry Hendrickson)
  * Changelog out of README
  * modified all documentation to use /etc/ddclient/ddclient.conf (notified by
    nicolasmartin in bug [1070646])

## v3.6.4

  * added support for NameCheap service (thanks to Dan Boardman)
  * added support for linksys ver2 (thanks to Dan Perik)

## v3.6.3

  * renamed sample-etc_dhclient-enter-hooks to sample-etc_dhclient-exit-hooks
  * add support for the Allnet 1298 Router
  * add -a to ifconfig to query all interfaces (for Solaris and OpenBSD)
  * update the process status to reflect what is happening.
  * add a To: line when sending e-mail
  * add mail-failure to send mail on failures only
  * try all addresses for multihomed hosts (like check.dyndns.org)
  * add support for dnspark
  * add sample for OrgDNS.org

## v3.6.2

  * add support for Xsense Aero
  * add support for Alcatel Speedtouch Pro
  * do authentication when either the login or password are defined.
  * fix parsing of web status pages

## v3.6

  * add support for EasyDNS (see easydns.com)
  * add warning for possible incorrect continuation lines in the .conf file.
  * add if-skip with the default as was used before.
  * add cmd-skip.

## v3.5.4

  * added !active result code for DynDNS.org

## v3.5.2

  * avoid undefined variable in get_ip

## v3.5.1

  * fix parsing of quoted strings in .conf file
  * add filename and line number to any warnings regarding files.

## v3.5

  * allow any url to be specified for -fw {address|url}.  use -fw-skip
    {pattern} to specify a string preceding the IP address at the URL's page
  * allow any url to be specified for -web {address|url}.  use -web-skip
    {pattern} to specify a string preceding the IP address at the URL's page
  * modify -test to display any IP addresses that could be obtained from any
    interfaces, builtin fw definitions, or web status pages.

## v3.4.6 (not released)

  * fix errors in -help
  * allow non-FQDNs as hosts; dslreports requires this.
  * handle german ifconfig output
  * try to get english messages from ifconfig so other languages are handled
    too.
  * added support for com 3c886a 56k Lan Modem

## v3.4.5

  * handle french ifconfig output

## v3.4.4

  * added support for obtaining the IP address from a Cisco DHCP interface.
    (Thanks, Tim)

## v3.4.2

  * update last modified time when nochg is returned from dyndns
  * add example regarding fw-login and fw-password's required by some home
    routers

## v3.4.1

  * add option (-pid) to record process id in a file. This option should be
    defined in the .conf file as it is done in the sample.
  * add detection of SIGHUP. When this signal is received, ddclient will wake
    up immediately, reload it's configuration file, and update the IP addresses
    if necessary.

## v3.4

  * ALL PEOPLE USING THIS CLIENT ARE URGED TO UPGRADE TO 3.4 or better.
  * fixed several timer related bugs.
  * reformatted some messages.

## v3.3.8

  * added support for the ISDN channels on ELSA LANCOM DSL/10 router

## v3.3.7

  * suppress repeated identical e-mail messages.

## v3.3.6

  * added support for the ELSA LANCOM DSL/10 router
  * ignore 0.0.0.0 when obtained from any FW/router.

## v3.3.5

  * fixed sample ddclient.conf.  fw-ip= should be fw=
  * fixed problem getting status pages for some routers

## v3.3.4

  * added support for the MaxGate's UGATE-3x00 routers

## v3.3.3

  * sample* correct checks for private addresses
  * add redhat specific sample-etc_rc.d_init.d_ddclient.redhat
  * make daemon-mode be the default when named ddclientd
  * added support for the Linksys BEF* Internet Routers

## v3.3.2

  * (sample-etc_rc.d_init.d_ddclient) set COLUMNS to a large number so that 'ps
    -aef' will not prematurely truncate the CMD.

## v3.3

  * added rpm (thanks to Bo Forslund)
  * added support for the Netgear RT3xx Internet Routers
  * modified sample-etc_rc.d_init.d_ddclient to work with other Unix beside
    RedHat.
  * avoid rewritting the ddclient.cache file unnecessarily
  * fixed other minor bugs

## v3.2.0

  * add support for DynDNS's custom domain service.
  * change suggested directory to /usr/sbin

## v3.1.0

  * clean up; fix minor bugs.
  * removed -refresh
  * add min-interval to avoid too frequent update attempts.
  * add min-error-interval to avoid too frequent update attempts when the
    service is unavailable.

## v3.0.1

  * make all values case sensitive (ie. passwords)

## v3.0

  * new release!
  * new ddclient.conf format
  * rewritten to support DynDNS's NIC2 and other dynamic DNS services
  * added Hammernode (hn.org)
  * added ZoneEdit (zoneedit.com)
  * added DSLreports (dslreports.com) host monitoring
  * added support for obtaining IP addresses from interfaces, commands, web,
    external commands, Watchguard's SOHO router Netopia's R910 router and SMC's
    Barracade
  * added daemon mode
  * added logging msgs to syslog and e-mail

## v2.3.7

  * add -refresh to the sample scripts so default arguments are obtained from
    the cache
  * added local-ip script for obtaining the address of an interface
  * added public-ip script for obtaining the ip address as seen from a public
    web page

## v2.3.6

  * fixed bug the broke enabling retrying when members.dyndns.org was down.

## v2.3.5

  * prevent warnings from earlier versions of Perl.

## v2.3.4

  * added sample-etc_dhclient-enter-hooks for those using the ISC DHCP client
    (dhclient)

## v2.3.3

  * make sure that ddclient.conf is only readable by the owner so that no one
    else can see the password (courtesy of Steve Greenland). NOTE: you will
    need to change the permissions on ddclient.conf to prevent others from
    obtaining viewing your password.  ie. chmod go-rwx /etc/ddclient.conf

## v2.3.2

  * make sure 'quiet' messages are printed when -verbose or -debug is enabled
  * fix error messages for those people using proxies.

## v2.3

  * fixed a problem reading in cached entries


## v2.2.1

  * sample-etc_ppp_ip-up.local - local ip address is $4 or $PPP_LOCAL (for
    debian)
  * use <CR><LF> as the line terminator (some proxies are strict about this)

## v2.2

  * added support (-static) for updating static DNS (thanks Marc Sira)
  * changed ddclient.cache format (old style is still read)
  * sample-etc_ppp_ip-up.local - detect improper calling sequences
  * sample-etc_ppp_ip-up.local - local ip address is $3 or $PPP_LOCAL (for
    debian)

## v2.1.2

  * updated README

## v2.1.1

  * make sure result code reflects any failures
  * optionally (-quiet) omit messages for unnecessary updates
  * update sample-etc_cron.d_ddclient to use -quiet

## v2.1

  * avoid unnecessary updates by recording the last hosts updated in a cache
    file (default /etc/ddclient.cache)
  * optionally (-force) force an update, even if it may be unnecessary.

    This can be used to prevent dyndns.org from deleting a host that has not
    required an update for a long period of time.
  * optionally (-refresh), reissue all host updates.

    This can be used together with cron to periodically update DynDNS.  See
    sample-etc-cron.d-ddclient for details.
  * optionally (-retry) save failed updates for future processing.

    This feature can be used to reissue updates that may have failed due to
    network connectivity problems or a DynDNS server outage
