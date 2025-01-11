package ddclient::t::Logger;
BEGIN { eval { require 'ddclient'; } or BAIL_OUT($@); }
use parent qw(-norequire ddclient::Logger);

{
    package ddclient::t::LoggerAbort;
    use overload '""' => qw(stringify);
    sub new {
        my ($class, %args) = @_;
        return bless(\%args, $class);
    }
    sub stringify {
        return 'logged a FATAL message';
    }
}

sub new {
    my ($class, $parent, $labelre) = @_;
    my $self = $class->SUPER::new(undef, $parent);
    $self->{logs} = [];
    $self->{_labelre} = $labelre;
    return $self;
}

sub _log {
    my ($self, $args) = @_;
    my $lre = $self->{_labelre};
    my $lbl = $args->{label};
    push(@{$self->{logs}}, $args) if !defined($lre) || (defined($lbl) && $lbl =~ $lre);
    return $self->SUPER::_log($args);
}

sub _abort {
    my ($self) = @_;
    push(@{$self->{logs}}, 'aborted');
    die(ddclient::t::LoggerAbort->new());
}

1;
