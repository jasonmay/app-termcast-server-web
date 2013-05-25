package App::Termcast::Server::Web::Socket::Handler;
use Moose;

use App::Termcast::Server::Web::Socket;

has connections => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::Web::Connections',
    required => 1,
);

sub run {
    my $self = shift;

    return sub {
       my $socket = shift;
       $socket->on(stream => sub {
           my ($socket, $stream) = @_;
           my $t_socket = $self->connections->find_socket($socket);
           $t_socket->stream($stream) if $t_socket;
       });
       my $t_socket = App::Termcast::Server::Web::Socket->new(handle => $socket);
       $self->connections->socket_handles->insert($t_socket);
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
