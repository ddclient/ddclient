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

AX_WITH_PROG([PERL], perl)
AX_PROG_PERL_VERSION([5.10.1], [],
  [AC_MSG_ERROR([Perl 5.10.1 or newer not found])])
AC_SUBST([PERL])

# Perl modules required to run ddclient. Core modules may be omitted;
# they are assumed to always exist.
m4_foreach_w([_m], [
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_ERROR([missing required Perl module _m])])])

# Perl modules required for tests. Only prints a warning if not
# installed.
m4_foreach_w([_m], [
    Test::Warnings
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_WARN([some tests may be skipped due to missing module _m])])])

AC_CONFIG_FILES([
    Makefile
    t/version.pl
  ])
AC_OUTPUT
