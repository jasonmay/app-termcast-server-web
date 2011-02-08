package App::Termcast::Server::Web::Hippie;
use Moose;
use Set::Object qw(set);

# { topic => handle }
has hippie_handles => (
    is => 'ro',
    isa => 'Set::Object',
    default => sub { set() },
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
