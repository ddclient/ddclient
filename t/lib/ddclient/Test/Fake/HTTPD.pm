# Copied from https://metacpan.org/pod/release/MASAKI/Test-Fake-HTTPD-0.08/lib/Test/Fake/HTTPD.pm
# and modified as follows:
#   * Patched with https://github.com/masaki/Test-Fake-HTTPD/pull/4 to add IPv6 support.
#   * Changed package name to ddclient::Test::Fake::HTTPD.
#
# License: This library is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package ddclient::Test::Fake::HTTPD;

use 5.008_001;
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Message::PSGI qw(res_from_psgi);
use Test::TCP qw(wait_port);
use URI;
use Time::HiRes ();
use Scalar::Util qw(blessed weaken);
use Carp qw(croak);
use Exporter qw(import);

our $VERSION = '0.08';
$VERSION = eval $VERSION;

our @EXPORT = qw(
    run_http_server run_https_server
    extra_daemon_args
);

our $ENABLE_SSL = eval { require HTTP::Daemon::SSL; 1 };
sub enable_ssl { $ENABLE_SSL }

our %EXTRA_DAEMON_ARGS = ();
sub extra_daemon_args (%) { %EXTRA_DAEMON_ARGS = @_ }

sub run_http_server (&) {
    my $app = shift;
    __PACKAGE__->new->run($app);
}

sub run_https_server (&) {} # noop
if ($ENABLE_SSL) {
    no warnings 'redefine';
    *run_https_server = sub (&) {
        my $app = shift;
        __PACKAGE__->new(scheme => 'https')->run($app);
    };
}

sub new {
    my ($class, %args) = @_;
    bless {
        host => '127.0.0.1',
        timeout => 5,
        listen => 5,
        scheme => 'http',
        %args
    }, $class;
}

our $DAEMON_MAP = {
    http  => 'HTTP::Daemon',
    https => 'HTTP::Daemon::SSL',
};

sub _daemon_class {
    my $self = shift;
    return $DAEMON_MAP->{$self->{scheme}};
}

sub run {
    my ($self, $app) = @_;

    my %extra_daemon_args = $self->{daemon_args} && ref $self->{daemon_args} eq 'HASH'
        ? %{ $self->{daemon_args} }
        : %EXTRA_DAEMON_ARGS;

    $self->{server} = Test::TCP->new(
        ($self->host ? (host => $self->host) : ()),
        code => sub {
            my $port = shift;

            my $d;
            for (1..10) {
                $d = $self->_daemon_class->new(
                    # Note: IO::Socket::IP ignores LocalAddr if LocalHost is set.
                    ($self->host ? (LocalAddr => $self->host) : ()),
                    LocalPort => $port,
                    Timeout   => $self->{timeout},
                    Proto     => 'tcp',
                    Listen    => $self->{listen},
                    ($self->_is_win32 ? () : (ReuseAddr => 1)),
                    %extra_daemon_args,
                ) and last;
                Time::HiRes::sleep(0.1);
            }

            croak(sprintf("failed to listen on address %s port %s%s",
                          $self->host || '<default>',
                          $self->port || '<default>',
                          $@ eq '' ? '' : ": $@")) unless $d;

            $d->accept; # wait for port check from parent process

            while (my $c = $d->accept) {
                while (my $req = $c->get_request) {
                    my $res = $self->_to_http_res($app->($req));
                    $c->send_response($res);
                }
                $c->close;
                undef $c;
            }
        },
        ($self->{port} ? (port => $self->{port}) : ()),
    );

    weaken($self);
    $self;
}

sub scheme {
    my $self = shift;
    return $self->{scheme};
}

sub host {
    my $self = shift;
    return $self->{host};
}

sub port {
    my $self = shift;
    return $self->{server} ? $self->{server}->port : 0;
}

sub host_port {
    my $self = shift;
    return $self->endpoint->host_port;
}

sub endpoint {
    my $self = shift;
    my $uri = URI->new($self->scheme . ':');
    my $host = $self->host;
    $host = 'localhost' if !defined($host) || $host eq '0.0.0.0' || $host eq '::';
    $uri->host($host);
    $uri->port($self->port);
    return $uri;
}

sub _is_win32 { $^O eq 'MSWin32' }

sub _is_psgi_res {
    my ($self, $res) = @_;
    return unless ref $res eq 'ARRAY';
    return unless @$res == 3;
    return unless $res->[0] && $res->[0] =~ /^\d{3}$/;
    return unless ref $res->[1] eq 'ARRAY' || ref $res->[1] eq 'HASH';
    return 1;
}

sub _to_http_res {
    my ($self, $res) = @_;

    my $http_res;
    if (blessed($res) and $res->isa('HTTP::Response')) {
        $http_res = $res;
    }
    elsif (blessed($res) and $res->isa('Plack::Response')) {
        $http_res = res_from_psgi($res->finalize);
    }
    elsif ($self->_is_psgi_res($res)) {
        $http_res = res_from_psgi($res);
    }

    croak(sprintf '%s: response must be HTTP::Response or Plack::Response or PSGI', __PACKAGE__)
        unless $http_res;

    return $http_res;
}

1;

=head1 NAME

Test::Fake::HTTPD - a fake HTTP server

=head1 SYNOPSIS

DSL-style

    use Test::Fake::HTTPD;

    my $httpd = run_http_server {
        my $req = shift;
        # ...

        # 1. HTTP::Response ok
        return $http_response;
        # 2. Plack::Response ok
        return $plack_response;
        # 3. PSGI response ok
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    printf "Listening on address:port %s\n", $httpd->host_port;
    # or
    printf "Listening on address %s port %s\n", $httpd->host, $httpd->port;

    # access to fake HTTP server
    use LWP::UserAgent;
    my $res = LWP::UserAgent->new->get($httpd->endpoint); # "http://127.0.0.1:{port}"

    # Stop http server automatically at destruction time.

OO-style

    use Test::Fake::HTTPD;

    my $httpd = Test::Fake::HTTPD->new(
        timeout     => 5,
        daemon_args => { ... }, # HTTP::Daemon args
    );

    $httpd->run(sub {
        my $req = shift;
        # ...
        [ 200, [ 'Content-Type', 'text/plain' ], [ 'Hello World' ] ];
    });

    # Stop http server automatically at destruction time.

=head1 DESCRIPTION

Test::Fake::HTTPD is a fake HTTP server module for testing.

=head1 FUNCTIONS

=over 4

=item * C<run_http_server { ... }>

Starts HTTP server and returns the guard instance.

  my $httpd = run_http_server {
      my $req = shift;
      # ...
      return $http_or_plack_or_psgi_res;
  };

  # can use $httpd guard object, same as OO-style
  LWP::UserAgent->new->get($httpd->endpoint);

=item * C<run_https_server { ... }>

Starts B<HTTPS> server and returns the guard instance.

If you use this method, you MUST install L<HTTP::Daemon::SSL>.

  extra_daemon_args
      SSL_key_file  => "certs/server-key.pem",
      SSL_cert_file => "certs/server-cert.pem";

  my $httpd = run_https_server {
      my $req = shift;
      # ...
      return $http_or_plack_or_psgi_res;
  };

  # can use $httpd guard object, same as OO-style
  my $ua = LWP::UserAgent->new(
      ssl_opts => {
          SSL_verify_mode => 0,
          verify_hostname => 0,
      },
  );
  $ua->get($httpd->endpoint);

=back

=head1 METHODS

=over 4

=item * C<new( %args )>

Returns a new instance.

  my $httpd = Test::Fake::HTTPD->new(%args);

C<%args> are:

=over 8

=item * C<timeout>

timeout value (default: 5)

=item * C<listen>

queue size for listen (default: 5)

=item * C<host>

local address to listen on (default: 127.0.0.1)

=item * C<port>

TCP port to listen on (default: auto detection)

=back

  my $httpd = Test::Fake::HTTPD->new(
      timeout => 10,
      listen  => 10,
      port    => 3333,
  );

=item * C<run( sub { ... } )>

Starts this HTTP server.

  $httpd->run(sub { ... });

=item * C<scheme>

Returns a scheme of running, "http" or "https".

  my $scheme = $httpd->scheme;

=item * C<host>

Returns the address the server is listening on.

=item * C<port>

Returns the TCP port the server is listening on.

  my $port = $httpd->port;

=item * C<host_port>

Returns the host:port from C<endpoint> (e.g., "127.0.0.1:1234", "[::1]:1234").

  my $host_port = $httpd->host_port;

=item * C<endpoint>

Returns a URI object to the running server (e.g., "http://127.0.0.1:1234",
"https://[::1]:1234"). If C<host> returns C<undef>, C<''>, C<'0.0.0.0'>,
or C<'::'>, the host portion of the URI is set to C<localhost>.

  use LWP::UserAgent;

  my $res = LWP::UserAgent->new->get($httpd->endpoint);

  my $url = $httpd->endpoint;
  $url->path('/foo/bar');
  my $res = LWP::UserAgent->new->get($url);

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::TCP>, L<HTTP::Daemon>, L<HTTP::Daemon::SSL>, L<HTTP::Message::PSGI>

=cut
