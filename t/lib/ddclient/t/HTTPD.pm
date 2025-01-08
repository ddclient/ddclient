package ddclient::t::HTTPD;

use v5.10.1;
use strict;
use warnings;

use parent qw(ddclient::Test::Fake::HTTPD);

use Exporter qw(import);
use Test::More;
BEGIN { require 'ddclient'; }
use ddclient::t::ip;

our @EXPORT = qw(
    httpd
    httpd_ok httpd_required $httpd_supported $httpd_support_error
    httpd_ipv6_ok httpd_ipv6_required $httpd_ipv6_supported $httpd_ipv6_support_error
    httpd_ssl_ok httpd_ssl_required $httpd_ssl_supported $httpd_ssl_support_error
    $ca_file $certdir $other_ca_file
    $textplain
);

our $httpd_supported;
our $httpd_support_error;
BEGIN {
    $httpd_supported = eval {
        require parent; parent->import(qw(ddclient::Test::Fake::HTTPD));
        require JSON::PP; JSON::PP->import();
        1;
    } or $httpd_support_error = $@;
}

sub httpd_ok {
    ok($httpd_supported, "HTTPD is supported") or diag($httpd_support_error);
}

sub httpd_required {
    plan(skip_all => $httpd_support_error) if !$httpd_supported;
}

our $httpd_ssl_supported = $httpd_supported;
our $httpd_ssl_support_error = $httpd_support_error;
$httpd_ssl_supported = eval { require HTTP::Daemon::SSL; 1; }
    or $httpd_ssl_support_error = $@
    if $httpd_ssl_supported;

sub httpd_ssl_ok {
    ok($httpd_ssl_supported, "SSL is supported") or diag($httpd_ssl_support_error);
}

sub httpd_ssl_required {
    plan(skip_all => $httpd_ssl_support_error) if !$httpd_ssl_supported;
}

our $httpd_ipv6_supported = $httpd_supported;
our $httpd_ipv6_support_error = $httpd_support_error;
$httpd_ipv6_supported = $ipv6_supported
    or $httpd_ipv6_support_error = $ipv6_support_error
    if $httpd_ipv6_supported;
$httpd_ipv6_supported = eval { require HTTP::Daemon; HTTP::Daemon->VERSION(6.12); }
    or $httpd_ipv6_support_error = $@
    if $httpd_ipv6_supported;

sub httpd_ipv6_ok {
    ok($httpd_ipv6_supported, "test HTTP server supports IPv6") or diag($httpd_ipv6_support_error);
}

sub httpd_ipv6_required {
    plan(skip_all => $httpd_ipv6_support_error) if !$httpd_ipv6_supported;
}

our $textplain = ['content-type' => 'text/plain; charset=utf-8'];

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_requests} = [];  # Log of received requests.
    $self->{_responses} = [];  # Script of responses to play back.
    return $self;
}

sub run {
    my ($self, $app) = @_;
    $self->SUPER::run(sub {
        my ($req) = @_;
        push(@{$self->{_requests}}, $req);
        my $res = $app->($req) if defined($app);
        return $res if defined($res);
        if ($req->uri()->path() eq '/control') {
            pop(@{$self->{_requests}});
            if ($req->method() eq 'PUT') {
                return [400, $textplain, ['content must be json']]
                    if $req->headers()->content_type() ne 'application/json';
                eval { @{$self->{_responses}} = @{decode_json($req->content())}; 1; }
                    or return [400, $textplain, ['content is not valid json']];
                @{$self->{_requests}} = ();
                return [200, $textplain, ["successfully reset request log and response script"]];
            } elsif ($req->method() eq 'GET') {
                my @reqs = map($_->as_string(), @{$self->{_requests}});
                return [200, ['content-type' => 'application/json'], [encode_json(\@reqs)]];
            } else {
                return [405, $textplain, ['unsupported method: ' . $req->method()]];
            }
        }
        return shift(@{$self->{_responses}}) // [500, $textplain, ["no more scripted responses"]];
    });
    diag("started server running at " . $self->endpoint());
    return $self;
}

sub reset {
    my $self = shift;
    my $ep = $self->endpoint();
    my $got = ddclient::geturl(url => "$ep/control");
    diag("http response:\n$got");
    ddclient::header_ok($got)
        or BAIL_OUT("failed to get log of requests from test http server at $ep");
    $got =~ s/^.*?\n\n//s;
    my @got = map(HTTP::Request->parse($_), @{decode_json($got)});
    ddclient::header_ok(ddclient::geturl(
                            url => "$ep/control",
                            method => 'PUT',
                            headers => ['content-type: application/json'],
                            data => encode_json(\@_),
                        )) or BAIL_OUT("failed to reset the test http server at $ep");
    return @got;
}

our $certdir = "$ENV{abs_top_srcdir}/t/lib/ddclient/Test/Fake/HTTPD";
our $ca_file = "$certdir/dummy-ca-cert.pem";
our $other_ca_file = "$certdir/other-ca-cert.pem";

my %daemons;

sub httpd {
    my ($ipv, $ssl) = @_;
    $ipv //= '';
    $ssl = !!$ssl;
    return undef if !$httpd_supported;
    return undef if $ipv eq '6' && !$httpd_ipv6_supported;
    return undef if $ssl && !$httpd_ssl_supported;
    if (!defined($daemons{$ipv}{$ssl})) {
        my $host
            = $ipv eq '4' ? '127.0.0.1'
            : $ipv eq '6' ? '::1'
            : $httpd_ipv6_supported ? '::1'
            : '127.0.0.1';
        $daemons{$ipv}{$ssl} = __PACKAGE__->new(
            host => $host,
            scheme => $ssl ? 'https' : 'http',
            daemon_args => {
                (V6Only => $ipv eq '6' ? 1 : 0) x ($host eq '::1'),
                (SSL_cert_file => "$certdir/dummy-server-cert.pem",
                 SSL_key_file => "$certdir/dummy-server-key.pem") x $ssl,
            },
        );
    }
    return $daemons{$ipv}{$ssl};
}

1;
