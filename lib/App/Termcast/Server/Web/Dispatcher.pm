package App::Termcast::Server::Web::Dispatcher;
use strict;
use warnings;
use Path::Dispatcher::Declarative -base, -default => {
    token_delimiter => '/',
};

on qr{^/$} => sub {
    my %args = @_;
    my $tt = delete $args{tt};;
    my $connections = delete $args{connections};

    #use Data::Dumper::Concise; die Dumper($connections);

    my $data;
    $tt->process('users.tt', {connections => $connections}, \$data);

    return $data;
};

on ['tv', qr/[\w-]+/] => sub {
    my %args        = @_;
    my $tt          = delete $args{tt};
    my $connections = delete $args{connections};
    my $params      = delete $args{params};
    my $stream_id   = $2;

    my $conn_fd = $connections->stream_to_fd->{$stream_id};
    my $stream  = $connections->streams->{$conn_fd};

    my $data;
    $tt->process('viewer.tt', { stream => $stream, params => $params }, \$data);

    return $data;
};

1;
