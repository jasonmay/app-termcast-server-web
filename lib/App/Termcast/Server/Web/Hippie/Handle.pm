package App::Termcast::Server::Web::Hippie::Handle;
use Moose;

has handle => (
    is => 'ro',
    required => 1,
);

has stream => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has vt => (
    is => 'ro',
    isa => 'Term::VT102::Incremental',
    lazy    => 1,
    builder => '_build_vt',
    clearer => 'clear_vt',
);

# need to keep track for when we lose it in the VT clearing
has ['lines', 'cols'] => (
    is  => 'rw',
    isa => 'Int',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if ($args{cols} and $args{lines} and not $args{vt}) {

        $self->cols($args{cols}  || 80);
        $self->lines($args{rows} || 24);

        $args{vt} = $self->make_vt(
            rows => delete $args{lines},
            cols => delete $args{cols},
        );
    }

    $self->$orig(%args);
};

sub _build_vt { shift->make_vt(); }

sub make_vt {
    my $self = shift;
    my %args = @_;

    $self->cols($args{cols})   if $args{cols};
    $self->lines($args{lines}) if $args{lines};

    $args{cols}  ||= $self->cols;
    $args{lines} ||= $self->lines;

    my $vt = Term::VT102::Incremental->new(%args);
    #$vt->vt->option_set('LINEWRAP', 1);

    return $vt;
}

sub send_clear_to_browser {
    my $self = shift;

    $self->handle->send_msg( [[0, 0, {clear => 1}]] );
}

sub send_to_browser {
    my $self = shift;
    my $buf  = shift;

    $self->vt->process($buf);
    my $updates = $self->vt->get_increment();

    # send 10 updates at a time
    # .. seems to fix the mysterious lag
    # that appears after a few hours
    while ( my @update_batch = splice @$updates, 0, 10) {
        $self->handle->send_msg({type => 'data', data => \@update_batch});
    }

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
