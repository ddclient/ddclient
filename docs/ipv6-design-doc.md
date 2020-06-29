# Design Doc: IPv6 Support

Author: [@rhansen](https://github.com/rhansen/)\
Date: 2020-06-09\
Signed off by:
[@SuperSandro2000](https://github.com/SuperSandro2000/)

## Objective

Add full IPv6 support to ddclient, including support for dual-stack
systems.

## Background

ddclient's current IPv6 support is limited:

  * Users can update either an IPv6 record or an IPv4 record for a
    host, not both.
  * If SSL is used for an HTTP request, IPv6 will be used if the
    remote host has a AAAA record, even if the user would rather use
    IPv4. This breaks `use=web` for IPv4 if the `web` URL's host has a
    AAAA record.
  * The `use=if` method only works if the user sets `if-skip` to
    something that skips over all IPv4 addresses in the output of
    `ifconfig` (or `ip`). If the output contains an IPv4 address after
    the IPv6 address then `use=if` cannot be used for IPv6.
  * There is no support for falling back to IPv4 if an IPv6 connection
    fails.
  * `use=if` does not filter out locally scoped or temporary IPv6
    addresses.

Some attempts have been made to add more robust IPv6 support:

  * Debian's ddclient package applies a
    [patch](https://salsa.debian.org/debian/ddclient/-/blob/67a138aa3d98d70f01766123f58ef40e98693fd4/debian/patches/usev6.diff)
    that adds a new `usev6` option. The `usev6` option can be set to
    `ip` or `if`, but not any of the other strategies currently
    available for the `use` option (`web`, `cmd`, `fw`, `cisco`,
    `cisco-asa`). When set to `ip` or `if`, only IPv6 addresses are
    considered; IPv4 addresses are ignored. The patch does not change
    the behavior of the `use` option, so `use=web` or `use=cmd` can be
    used for IPv6 if pointed at something that only outputs an IPv6
    address.
  * [ddclient-curl](https://github.com/astlinux-project/ddclient-curl)
    is a fork of ddclient that uses curl as the HTTP client (instead
    of ddclient's own homemade client) for more robust IPv6 support.
  * PR #40 is perhaps the most comprehensive attempt at adding full
    IPv6 support, but it was never merged and has since
    bit-rotted. There is renewed effort to rebase the changes and get
    them merged in. PR #40 adds new options and changes some existing
    options. The approach taken is to completely isolate IPv4 address
    detection from IPv6 address detection and require the update
    protocol callbacks to handle each type of address appropriately.

## Requirements

  * The mechanism for determining the current IPv4 address (the `use`
    option) must be independently configurable from the mechanism used
    to determine the current IPv6 address.
  * The user must be able to disable IPv4 address updates without
    affecting IPv6 updates.
  * The user must be able to disable IPv6 address updates without
    affecting IPv4 updates.
  * If HTTP polling is used for both IPv4 and IPv6 address discovery,
    the URL used to determine the IPv4 address (the `web` option) must
    be independently configurable from the URL used to determine the
    IPv6 address.
  * The use of IPv4 or IPv6 to update a record must be independent of
    the type of record being updated (IPv4 or IPv6).
  * The callback for the update protocol must be given both addresses,
    even if only one of the two addresses has changed.
  * The callback for the update protocol must be told which addresses
    have changed.
  * There must be IPv6 equivalents to `use=ip`, `use=if`, `use=web`,
    and `use=cmd`. For the IPv6 equivalent to `use=if`, it is
    acceptable to ignore non-global and temporary addresses (the user
    can always use the IPv6 equivalent to `use=cmd` to get non-global
    or temporary addresses).
  * Existing support for updating IPv6 records must not be lost.
  * Some dynamic DNS service providers use separate credentials for
    the IPv4 and IPv6 records. These providers must be supported,
    either by accepting both sets of credentials in a single host's
    configuration or by allowing the user to specify the same host
    twice, once for IPv4 and once for IPv6.

### Nice-to-Haves

  * The user should be able to force the update protocol to use IPv4
    or IPv6.
  * Unless configured otherwise, ddclient should first attempt to
    update via IPv6 and fall back to IPv4 if the IPv6 connection
    fails. This behavior can be added later; for now it is acceptable
    to keep the current behavior (use IPv6 without IPv4 fallback if
    there is a AAAA record, use IPv4 if there is no AAAA record).
  * Full backwards compatibility with existing config files and
    flags. The trade-offs between migration burden, long-term
    usability, and code maintenance should be carefully considered.
  * IPv6 equivalents to `use=fw`, `use=cisco`, and `use=cisco-asa`.
  * Add IPv6 support in protocol callbacks where IPv6 support is
    currently missing. (This can be done later.)

## Proposal

### Configuration changes

  * Add new `usev4` and `usev6` settings that are like the current
    `use` setting except they only apply to IPv4 and IPv6,
    respectively.
      * `usev4` can be set to one of the following values: `disabled`,
        `ipv4`, `webv4`, `fwv4`, `ifv4`, `cmdv4`, `ciscov4`,
        `cisco-asav4`
      * `usev6` can be set to one of the following values: `disabled`,
        `ipv6`, `webv6`, `fwv6`, `ifv6`, `cmdv6`, `ciscov6`,
        `cisco-asav6`
  * Add a new `use` strategy: `disabled`.
  * The `disabled` value for `use`, `usev4`, and `usev6` causes
    ddclient to act as if it was never set. This is useful for
    overriding the global value for a particular host.
  * For compatibility with ddclient-curl, `no` is a deprecated alias
    of `disabled`.
  * Add new `ipv4`, `ipv6`, `webv4`, `webv4-skip`, `webv6`,
    `webv6-skip`, `ifv4`, `ifv6`, `cmdv4`, `cmdv6`, etc. settings that
    behave like their versionless counterparts except they only apply
    to IPv4 or IPv6. Deprecate the versionless counterparts, and
    change their behavior so that they also influence the default
    value of the versioned options. (Example:  Suppose
    `usev4=ifv4`. If `ifv4` is not set then `if` is used.)  Special
    notes:
      * The value of `ip` will only serve as the default for `ipv4`
        (or `ipv6`) if it contains an IPv4 (or IPv6) address.
      * There is currently an `ipv6` boolean setting. To preserve
        backward compatibility with existing configs, `ipv6` set to a
        boolean value is ignored (other than a warning).
      * There is no `ifv4-skip` or `ifv6-skip` because it's ddclient's
        responsibility to properly parse the output of whatever tool
        it uses to read the interface's addresses.
      * For now there is no `cmdv4-skip` or `cmdv6-skip`. Anyone who
        already knows how to write a regular expression can probably
        write a wrapper script. These may be added in the future if
        users request them, especially if it facilitates migration
        away from the deprecated `cmd-skip` setting.
      * For `usev6=ifv6`, interfaces are likely to have several IPv6
        addresses (unlike IPv4). Choosing the "right" IPv6 address is
        not trivial. Fortunately, we don't have to solve this
        perfectly right now; we can choose something that mostly
        works and let user bug reports guide future refinements. For
        the first iteration, we will try the following:
          * Ignore addresses that are not global unicast.
            (Unfortunately, the `ip` command from iproute2 does not
            provide a way to filter out ULA addresses so we will have
            to do this ourselves.)
          * Ignore temporary addresses.
          * If no addresses remain, log a warning and don't update the
            IPv6 record.
          * Otherwise, if one of the remaining addresses matches the
            previously selected address, continue to use it.
          * Otherwise, select one arbitrarily.
  * Deprecate the `use` setting (print a loud warning) but keep its
    existing semantics with an exception: If there is a conflict with
    `usev4` or `usev6` then those take priority:
      * If `use`, `usev4`, and `usev6` are all set then a warning is
        logged and the `use` setting is ignored.
      * If `use` and `usev4` are both set and the `use` strategy
        discovers an IPv4 address that differs from the address
        discovered by the `usev4` strategy, then the address from
        `usev4` is used and a warning is logged.
      * If `use` and `usev6` are both set and the `use` strategy
        discovers an IPv6 address that differs from the address
        discovered by the `usev6` strategy, then the address from
        `usev6` is used and a warning is logged.
  * If `usev4` (`usev6`) is not set:
      * If `ipv4` (`usev6`) is set, ddclient acts as if `usev4`
        (`usev6`) was set to `ipv4` (`ipv6`).
      * Otherwise, if `ifv4` (`ifv6`) is set, ddclient acts as if
        `usev4` (`usev6`) was set to `ifv4` (`ifv6`).
      * Otherwise, if `cmdv4` (`cmdv6`) is set, ddclient acts as if
        `usev4` (`usev6`) was set to `cmdv4` (`cmdv6`).
      * Otherwise, if `fwv4` (`fwv6`) is set, ddclient acts as if
        `usev4` (`usev6`) was set to `fwv4` (`fwv6`).
      * Otherwise, `usev4` (`usev6`) remains unset.
  * To support separate credentials for IPv4 vs. IPv6 updates, users
    can specify the same host multiple times, each time with different
    options.

### Internal API changes

  * Add two new entries to the `$config{$host}` hash:
      * `$config{$host}{'wantipv4'}` is set to:
          * If `usev4` is enabled, the IPv4 address discovered by the
            `usev4` strategy.
          * Otherwise, if `use` is enabled and the `use` strategy
            discovered an IPv4 address, the IPv4 address discovered by
            the `use` strategy.
          * Otherwise, `undef`.
      * `$config{$host}{'wantipv6'}` is set to:
          * If `usev6` is enabled, the IPv6 address discovered by the
            `usev6` strategy.
          * Otherwise, if `use` is enabled and the `use` strategy
            discovered an IPv6 address, the IPv6 address discovered by
            the `use` strategy.
          * Otherwise, `undef`.
  * Deprecate the existing `$config{$host}{'wantip'}` entry, to be
    removed after all update protocol callbacks have been updated to
    use the above new entries. In the meantime, this entry's value
    depends on which of `use`, `usev4`, and `usev6` is enabled, and
    what type of IP address is discovered by the `use` strategy (if
    enabled), according to the following table:

    | `use` | `usev4` | `usev6` | resulting value |
    | :---: | :---: | :---: | :--- |
    | ✔(IPv4) | ✖ | ✖ | the IPv4 address discovered by the `use` strategy |
    | ✔(IPv6) | ✖ | ✖ | the IPv6 address discovered by the `use` strategy |
    | ✖ | ✔ | ✖ | the IPv4 address discovered by the `usev4` strategy |
    | ✖ | ✖ | ✔ | the IPv6 address discovered by the `usev6` strategy |
    | ✔(IPv4) | ✔ | ✖ | the IPv4 address discovered by the `usev4` strategy (and log another warning if it doesn't match the IPv4 address found by the `use` strategy) |
    | ✔(IPv6) | ✔ | ✖ | the IPv6 address discovered by the `use` strategy |
    | ✔(IPv4) | ✖ | ✔ | the IPv4 address discovered by the `use` strategy |
    | ✔(IPv6) | ✖ | ✔ | the IPv6 address discovered by the `usev6` strategy (and log another warning if it doesn't match the IPv6 address found by the `use` strategy) |

  * To support separate credentials for IPv4 vs. IPv6 updates, convert
    the `%config` hash of host configs into a list of host configs. A
    second definition for the same host adds a second entry rather
    than overwrites the existing entry.

## Alternatives Considered

### Repurpose the existing settings for v4

Rather than create new `usev4`, `ifv4`, `cmdv4`, etc. settings,
repurpose the existing `use`, `if`, `cmd`, etc. settings for IPv4.

Why this was rejected:
  * There is a usability advantage to the symmetry with the `v6`
    settings.
  * It is easier to remain compatible with existing configurations.

### Let `use` set the default for `usev4`

Rather than three separate IP discovery mechanisms (`use`, `usev4`,
and `usev6`), have just two (`usev4` and `usev6`) and let the old
`use` setting control the default for `usev4`: If `usev4` is not set,
then `use=foo` is equivalent to `usev4=foov4`.

Why this was rejected: Backwards incompatibility. Specifically,
configurations that previously updated an IPv6 record would instead
(attempt to) update an IPv4 record.

### Let `use` set the default for `usev4` and `usev6`

Rather than three separate IP discovery mechanisms (`use`, `usev4`,
and `usev6`), have just two (`usev4` and `usev6`) and let the old
`use` setting control the default for `usev4` and `usev6`:

  * If neither `usev4` nor `usev6` is set, then `use=foo` is
    equivalent to `usev4=foov4,usev6=foov6`.
  * If `usev4` is set but not `usev6`, then `use=foo` is equivalent to
    `usev6=foov6`.
  * If `usev6` is set but not `usev4`, then `use=foo` is equivalent to
    `usev4=foov4`.
  * If both `usev4` and `usev6` are set, then `use=foo` is ignored.

Why this was rejected: The new design would cause existing
configurations to trigger surprising, and possibly undesired (e.g.,
timeouts or update errors), new behavior:

  * Configurations that previously updated only an IPv4 record would
    also update an IPv6 record.
  * Similarly, configurations that previously updated only an IPv6
    record would also update an IPv4 record.

### Replace uses of `'wantip'` with `'wantipv4'`

Rather than support `'wantip'`, `'wantipv4'`, and `'wantipv6'`, just
replace all `'wantip'` references to `'wantipv4'`.

Why this was rejected: This would break compatibility for users that
are currently updating IPv6 addresses. (Compatibility would be
restored once the update protocol callbacks are updated to honor
`'wantipv6'`.)

### Single `if` setting for both `usev4=if` and `usev6=if`

The proposed design calls for separate `ifv4` and `ifv6` settings. If
the user sets `usev4=if,usev6=if`, then the user most likely wants to
use the same interface for both IPv4 and IPv6. Rather than create
separate `ifv4` and `ifv6` settings, have a single `if` setting used
for both `usev4` and `usev6`.

Why this was rejected:
  * Separate `v4` and `v6` settings adds consistency to the
    configuration.
  * There are cases where a user will want to use a different
    interface. In particular, an IPv6 over IPv4 tunnel (e.g.,
    https://tunnelbroker.net) involves creating a separate interface
    that is used only for IPv6.

### Separate IPv4 and IPv6 credentials

In order to support providers that use separate credentials for IPv4
and IPv6 updates, the proposed design allows the user to define the
same host twice. We could instead add additional options so that the
user can provide both sets of credentials in a single host definition.

Why this was rejected:
  * The proposed design is easier to implement, as it does not require
    any modifications to existing protocol implementations.
  * The proposed design is less likely to cause problems for users
    that rely on globals instead of host-specific options. For
    example, a configuration file like the following might not do what
    the user expects:

    ```
    ssl=true, use=if, if=eth0

    protocol=foo
    login=username-for-ipv4
    password=password-for-ipv4
    loginv6=username-for-ipv6
    passwordv6=password-for-ipv6
    myhost.example.com

    protocol=bar
    login=username
    password=password
    # This host definition will use loginv6, passwordv6 from above
    # because the user didn't end each setting with a line
    # continuation:
    my-other-host.example.com
    ```

  * The proposed design provides some bonus functionality:
      * Users can smoothly transition between different providers by
        updating both providers simultaneously until the domain
        registration switches to the new registrar.
      * Users can take advantage of providers that support multiple A
        or multiple AAAA records for the same hostname, assuming each
        record has independent credentials.
