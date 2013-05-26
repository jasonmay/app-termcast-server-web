package App::Termcast::Server::Web::Socket::Handler;
use Moose;

use App::Termcast::Server::Web::Socket;
use JSON;

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
           $socket->emit('ready');

       });
       $socket->on(ready => sub {
           my ($socket) = @_;
           my $t_socket = $self->connections->find_socket($socket);
           my $stream = $t_socket->stream;
           my $stream_data = $self->connections->get_stream($stream);
           $t_socket->send_to_browser($stream_data->buffer);
       });

       my $t_socket = App::Termcast::Server::Web::Socket->new(handle => $socket);
       $self->connections->socket_handles->insert($t_socket);
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
