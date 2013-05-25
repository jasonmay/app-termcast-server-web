package App::Termcast::Server::Web::Connections;
use Moose;

use AnyEvent::Socket;
use App::Termcast::Server::Web::Stream;
use App::Termcast::Connector;

use Set::Object 'set';

has streams => (
    is      => 'ro',
    isa     => 'HashRef[App::Termcast::Server::Web::Stream]',
    traits  => ['Hash'],
    handles => {
        set_stream    => 'set',
        delete_stream => 'delete',
    },
    default  => sub { +{} },
    clearer  => 'clear_streams',
    weak_ref => 1,
);

has socket_handles => (
    is  => 'ro',
    isa => 'Set::Object',
    default => sub { set() },
);

has config => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has tc_handle => (
    is  => 'rw',
    isa => 'AnyEvent::Handle',
);

has stream_to_fd => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

# sometimes we get stream notices before
# a connection is even establish. in that
# situation we store them in this attr
# until we are ready
has notice_buffer => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has connector => (
    is => 'ro',
    isa => 'App::Termcast::Connector',
    default => sub { App::Termcast::Connector->new },
);

sub _read_event {
    my $self = shift;
    my $h = shift;

    $h->push_read(json => sub {
        my ($h, $data) = @_;
        $self->connector->dispatch($data, decoded => 1);
    });
}

sub _ask_for_stream_list {
    my $self = shift;
    my $h    = shift;

    $h->push_write(
        json => +{request => 'sessions'}
    );
}

sub check_if_unprepared {
    my $self      = shift;
    my ($type, $session_id, @stuff) = @_;

    if (!$self->stream_to_fd->{$session_id}) {
        $self->notice_buffer->{$session_id} ||= [];
        push @{ $self->notice_buffer->{$session_id} },
             [ $type, @stuff ];

        return 0;
    }

    return 1;
}

sub handle_metadata {
    my $self = shift;
    my ($stream_id, $metadata) = @_;

    my $stream = $self->get_stream($stream_id);

    if ($metadata->{geometry}) {
        my ($cols, $lines) = @{$metadata->{geometry}};
        $stream->cols($cols);
        $stream->lines($lines);

        my @handles =
            grep { $_->stream eq $stream_id }
            $self->socket_handles->members;

        foreach my $hh (@handles) {
            $hh->send_resize_to_browser($cols, $lines);
        }
    }
}

sub get_stream_from_handle {
    my $self   = shift;
    my $handle = shift;
    my $fd     = fileno($handle->fh);

    return $self->streams->{$fd};
}

sub make_stream {
    my $self       = shift;
    my %args       = @_;

    my %params = (
        id          => $args{session_id},
        username    => $args{user},
        last_active => DateTime->from_epoch(epoch => $args{last_active}),
        connections => $self,
        cols        => $args{geometry}->[0],
        lines       => $args{geometry}->[1],
    );

    #use Data::Dumper::Concise; warn Dumper(\%params);
    my $stream = App::Termcast::Server::Web::Stream->new(%params);

    $stream->connect($args{socket});
}

sub get_stream {
    my $self      = shift;
    my $stream_id = shift;

    my $fd = $self->stream_to_fd->{$stream_id};
    return undef unless $fd;
    return $self->streams->{$fd};
}

sub find_socket {
    my $self       = shift;
    my $socket = shift;

    my @websockets = $self->socket_handles->members;
    for my $websocket (@websockets) {
        return $websocket if $socket->id eq $websocket->id;
    }
    return undef;
}

sub vivify_connection {
    my $self = shift;

    my $sessions_cb = sub {
        my ($connector, @sessions) = @_;
        $self->clear_streams;

        foreach my $conn_data (@sessions) {
            $self->make_stream(%$conn_data);
        }
    };

    my $connect_cb = sub {
        my ($connector, $data) = @_;
        $self->make_stream(%$data);
    };

    my $disconnect_cb = sub {
        my ($connector, $session_id) = @_;

        $self->check_if_unprepared('disconnect', $session_id) or return;

        my $fd        = $self->stream_to_fd->{$session_id};
        $self->delete_stream($fd);
    };

    my $metadata_cb = sub {
        my ($connector, $session_id, $data) = @_;
        $self->check_if_unprepared('metadata', $session_id, $data) or return;
        $self->handle_metadata($session_id, $data);
    };

    $self->connector->register_sessions_callback($sessions_cb);
    $self->connector->register_connect_callback($connect_cb);
    $self->connector->register_disconnect_callback($disconnect_cb);
    $self->connector->register_metadata_callback($metadata_cb);

    require Cwd;
    tcp_connect 'unix/', Cwd::abs_path($self->config->{socket}), sub {
        my ($fh) = @_ or die $!;

        my $handle = AnyEvent::Handle->new(
            fh => $fh,
            on_read => sub {
                my $h = shift;
                $self->_read_event($h);
            },
            on_error => sub {
                my ($h, $fatal, $error) = @_;
                warn $error;
                exit 1 if $fatal;
            },
        );

        $self->tc_handle($handle);

        $self->_ask_for_stream_list($handle);
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
