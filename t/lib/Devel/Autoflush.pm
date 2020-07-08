package Devel::Autoflush;
# ABSTRACT: Set autoflush from the command line
our $VERSION = '0.06'; # VERSION

my $kwalitee_nocritic = << 'END';
# can't use strict as older stricts load Carp and we can't allow side effects
use strict;  
END

my $old = select STDOUT;
$|++;
select STDERR;
$|++;
select $old;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Autoflush - Set autoflush from the command line

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 perl -MDevel::Autoflush Makefile.PL

=head1 DESCRIPTION

This module is a hack to set autoflush for STDOUT and STDERR from the command
line or from C<PERL5OPT> for code that needs it but doesn't have it.

This often happens when prompting:

  # guess.pl
  print "Guess a number: ";
  my $n = <STDIN>;

As long as the output is going to a terminal, the prompt is flushed when STDIN
is read.  However, if the output is being piped, the print statement will 
not automatically be flushed, no prompt will be seen and the program will
silently appear to hang while waiting for input.  This might happen with 'tee':

  $ perl guess.pl | tee capture.out

Use Devel::Autoflush to work around this:

  $ perl -MDevel::Autoflush guess.pl | tee capture.out

Or set it in C<PERL5OPT>:

  $ export PERL5OPT=-MDevel::Autoflush
  $ perl guess.pl | tee capture.out

= SEE ALSO

=over 4

=item *

L<CPANPLUS::Internals::Utils::Autoflush> -- same idea but STDOUT only and 

only available as part of the full CPANPLUS distribution

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Devel-Autoflush/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Devel-Autoflush>

  git clone https://github.com/dagolden/Devel-Autoflush.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
