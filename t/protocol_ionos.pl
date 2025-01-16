use Test::More;
BEGIN { eval { require Test::Warnings; } or skip($@, 1); }
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
BEGIN {
    eval { require ddclient::t::HTTPD; 1; } or plan(skip_all => $@);
    ddclient::t::HTTPD->import();
    plan tests => 2;
}

{
    package Logger;
    use parent qw(-norequire ddclient::Logger);
    sub new {
        my ($class, $parent) = @_;
        my $self = $class->SUPER::new(undef, $parent);
        $self->{logs} = [];
        return $self;
    }
    sub _log {
        my ($self, $args) = @_;
        push(@{$self->{logs}}, $args)
            if ($args->{label} // '') =~ qr/^(?:WARNING|FATAL|SUCCESS|FAILED)$/;
        return $self->SUPER::_log($args);
    }
}

# Subtest for the protocol_ionos
subtest 'Testing protocol_ionos' => sub {
    # Mock HTTP server
    httpd()->run(sub {
        my ($req) = @_;
        diag('==============================================================================');
        diag("Test server received request:\n" . $req->as_string());

        return undef if $req->uri()->path() eq '/control';
        return [400, $textplain, ['invalid method: ' . $req->method()]] if $req->method() ne 'GET';
        return undef
    });

    local $ddclient::globals{debug} = 1;
    local $ddclient::globals{verbose} = 1;
    my $l = Logger->new($ddclient::_l);

    local %ddclient::config = (
        'host.my.example.com' => {
            'protocol' => 'ionos',
            'password' => 'mytestingpassword',
            'server'   => httpd()->endpoint(),
            'wantipv4' => '1.2.3.4',
        },
    );

    httpd()->reset([200, $textplain, []]);

    {
        local $ddclient::_l = $l;

        ddclient::nic_ionos_update(undef, 'host.my.example.com');
    }

    my @requests = httpd()->reset();
    is(scalar(@requests), 1, "Single update request");

    my $req = shift(@requests);
    is($req->uri()->path(), '/dns/v1/dyndns', "Correct request path");
    is($req->uri()->query(), 'q=mytestingpassword', "Correct request query");
};

done_testing();
