package ddclient::t::Logger;
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
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

1;
