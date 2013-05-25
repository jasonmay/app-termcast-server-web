package App::Termcast::Server::Web::TV;
use Moose;
use DateTime::Format::Human::Duration;

has tt => (
    is      => 'ro',
    isa     => 'Template',
    required => 1,
);

has connections => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::Web::Connections',
    required => 1,
);

has config => (
    is       => 'ro',
    required => 1,
);

# render list of users
sub users {
    my $self = shift;
    my ($r) = @_;

    my $connections = $self->connections;
    my $tt = $self->tt;

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
}

sub about {
    my $self = shift;
    my ($r) = @_;

    my $tt = $self->tt;
    my $data;
    $tt->process('about.tt', {}, \$data);
    return $data;
}

# view a streamer
sub view {
    my $self = shift;
    my ($r, $id) = @_;

    my $tt          = $self->tt;
    my $connections = $self->connections;
    my $config      = $self->config;

    my $conn_fd = $connections->stream_to_fd->{$id};
    my $data;

    if ($conn_fd and $connections->streams->{$conn_fd}) {
        my $stream  = $connections->streams->{$conn_fd};
        $tt->process(
            'viewer.tt', {
                config          => $config,
                stream          => $stream,
                params          => $r->parameters,
                viewer_template => 'terminal.tt'
            }, \$data
        );
    }
    else {
        $tt->process(
            'viewer.tt', {
                config          => $config,
                viewer_template => 'notfound.tt',
            }, \$data
        );
    }

    return $data;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
