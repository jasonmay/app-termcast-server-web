package App::Termcast::Server::Web::Hippie;
use Moose;

# { topic => handle }
has hippie_handles => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
