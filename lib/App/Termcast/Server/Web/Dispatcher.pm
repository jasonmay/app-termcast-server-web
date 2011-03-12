package App::Termcast::Server::Web::Dispatcher;
use strict;
use warnings;
use Path::Dispatcher::Declarative -base, -default => {
    token_delimiter => '/',
};

use DateTime::Format::Human::Duration;

on qr{^/$} => sub {
    my %args = @_;
    my $tt = delete $args{tt};;
    my $connections = delete $args{connections};

    my @hh = $connections->hippie->hippie_handles->members;
    my %stream_data;

    my @streams = values %{$connections->streams || {}};
    my $dur = DateTime::Format::Human::Duration->new;

    foreach my $stream (@streams) {
        $stream_data{$stream->id}{idle} = $dur->format_duration_between(
            $connections->get_stream($stream->id)->last_active,
            DateTime->now,
        );

        $stream_data{$stream->id}{object} = $stream;
    }

    my $data;
    $tt->process(
        'users.tt', {
            connections => $connections,
            stream_data => \%stream_data,
        },
        \$data
    );

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
