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
