AC_PREREQ([2.63])
AC_INIT([ddclient], [3.9.1])
AC_CONFIG_SRCDIR([ddclient.in])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_REQUIRE_AUX_FILE([tap-driver.sh])
# If the automake dependency is bumped to v1.12 or newer, remove
# build-aux/tap-driver.sh from the repository.  Automake 1.12+ comes
# with tap-driver.sh, and autoreconf will copy in the version
# distributed with automake.  (Automake 1.11 and older don't come with
# tap-driver.sh, so build-aux/tap-driver.sh is checked in to keep the
# above AC_REQUIRE_AUX_FILE line from causing configure to complain
# about a mising file if the user has Automake 1.11.)
AM_INIT_AUTOMAKE([1.11 -Wall -Werror foreign subdir-objects parallel-tests])
AM_SILENT_RULES

AC_PROG_MKDIR_P

# The Fedora Docker image doesn't come with the 'findutils' package.
# 'find' is required for 'make distcheck', which the user might not
# run. We could log a warning instead of erroring out, but:
#   * a warning is unlikely to be seen,
#   * 'make distcheck' doesn't yield a non-0 exit code if 'find' is
#     not available,
#   * 'find' is a core utility that should always be available, and
#   * we might use 'find' for other purposes in the future.
AC_PATH_PROG([FIND], [find])
AS_IF([test -z "${FIND}"], [AC_MSG_ERROR(['find' utility not found])])

AC_PATH_PROG([CURL], [curl])

AX_WITH_PROG([PERL], perl)
AX_PROG_PERL_VERSION([5.10.1], [],
  [AC_MSG_ERROR([Perl 5.10.1 or newer not found])])
AC_SUBST([PERL])

# Perl modules required to run ddclient. Note: CentOS, RHEL, and
# Fedora put some core modules in separate packages, and the perl
# package doesn't depend on all of them, so their availability can't
# be assumed.
m4_foreach_w([_m], [
    File::Basename
    File::Path
    File::Temp
    Getopt::Long
    IO::Socket::INET
    Socket
    Sys::Hostname
    version=0.77
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_ERROR([missing required Perl module _m])])])

# Perl modules required for tests. If these modules are not installed
# then some tests will fail. Only prints a warning if not installed.
m4_foreach_w([_m], [
    B
    Data::Dumper
    File::Spec::Functions
    File::Temp
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_WARN([some tests will fail due to missing module _m])])])

# Optional Perl modules for tests. If these modules are not installed
# then some tests will be skipped, but no tests should fail. Only
# prints a warning if not installed.
m4_foreach_w([_m], [
    Carp
    Exporter
    HTTP::Daemon=6.12
    HTTP::Daemon::SSL
    HTTP::Message::PSGI
    HTTP::Request
    HTTP::Response
    IO::Socket::INET6
    IO::Socket::IP
    IO::Socket::SSL
    Scalar::Util
    Test::MockModule
    Test::TCP
    Test::Warnings
    Time::HiRes
    URI
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_WARN([some tests may be skipped due to missing module _m])])])

AC_CONFIG_FILES([
    Makefile
    t/geturl_connectivity.pl
    t/version.pl
  ])
AC_OUTPUT
