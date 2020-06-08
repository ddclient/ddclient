AC_PREREQ([2.63])
AC_INIT([ddclient], [3.9.1])
AC_CONFIG_SRCDIR([ddclient.template])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([1.11 -Wall -Werror foreign subdir-objects])
AM_SILENT_RULES

AC_PROG_MKDIR_P

AX_WITH_PROG([PERL], perl)
AX_PROG_PERL_VERSION([5.10.1], [],
  [AC_MSG_ERROR([Perl 5.10.1 or newer not found])])
AC_SUBST([PERL])

m4_foreach_w([_m], [
  ], [AX_PROG_PERL_MODULES([_m], [],
         [AC_MSG_ERROR([missing required Perl module _m])])])

AC_CONFIG_FILES([
    Makefile
  ])
AC_OUTPUT
