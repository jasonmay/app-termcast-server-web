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

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    warn "@_";
    my %args = @_;

    if ($args{cols} and $args{lines} and not $args{vt}) {
        $args{vt} = Term::VT102::Incremental->new(
            rows => delete $args{lines},
            cols => delete $args{cols},
        );
    }

    $self->$orig(%args);
};

sub _build_vt {
    Term::VT102::Incremental->new();
}

sub send_to_browser {
    my $self = shift;
    my $buf  = shift;

    $self->vt;
    $self->vt->process($buf);
    my $updates = $self->vt->get_increment();

    $self->handle->send_msg($updates);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
