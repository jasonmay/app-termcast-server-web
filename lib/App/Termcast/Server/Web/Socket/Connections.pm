package App::Termcast::Server::Web::Socket::Connections;
use Moose;

has connections => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
