package App::Termcast::Server::Web::Hippie::Handle;
use Moose;

use App::Termcast::Server::Web::VT102i;
use App::Termcast::Server::Web::VT102;

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
    isa => 'App::Termcast::Server::Web::VT102i',
    lazy    => 1,
    builder => '_build_vt',
    clearer => 'clear_vt',
);

# need to keep track for when we lose it in the VT clearing
has lines => (
    is      => 'rw',
    isa     => 'Int',
    default => 24,
);
has cols => (
    is      => 'rw',
    isa     => 'Int',
    default => 80,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if ($args{cols} and $args{lines} and not $args{vt}) {

        $args{vt} = $self->make_vt(
            rows => $args{lines},
            cols => $args{cols},
        );
    }

    $self->$orig(%args);
};

sub _build_vt {
    my $self = shift;
    $self->make_vt(
        rows => $self->lines,
        cols  => $self->cols,
    );
}

sub make_vt {
    my $self = shift;
    my %args = @_;

    my $vt = App::Termcast::Server::Web::VT102i->new(%args);
    $vt->vt->option_set('LINEWRAP', 1);

    return $vt;
}

sub send {
    my $self = shift;
    my $data = shift;
    $self->handle->send_msg({type => 'data', data => $data});
}

sub send_clear_to_browser {
    my $self = shift;

    $self->send([[0, 0, {clear => 1}]]);
}

sub send_disconnect_to_browser {
    my $self = shift;

    $self->send([[0, 0, {disconnect => 1}]]);
}

sub send_resize_to_browser {
    my $self = shift;
    my ($cols, $lines) = @_;

    $self->lines($lines);
    $self->cols($cols);

    $self->clear_vt;
    $self->send( [[0, 0, {resize => [$cols, $lines]}]] );
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
        $self->send( \@update_batch );
    }

}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
