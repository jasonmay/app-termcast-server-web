package App::Termcast::Server::Web::Connections;
use Moose;

use AnyEvent::Socket;

use App::Termcast::Server::Web::Stream;

has streams => (
    is => 'ro',
    isa => 'HashRef[App::Termcast::Server::Web::Stream]',
    traits => ['Hash'],
    handles => {
        set_stream    => 'set',
        delete_stream => 'delete',
    },
    clearer => 'clear_streams',
);

# websocket handles from Web::Hippie
has hippie => (
    is => 'ro',
    isa => 'App::Termcast::Server::Web::Hippie',
    required => 1,
);

has tc_socket => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has tc_handle => (
    is => 'rw',
    isa => 'AnyEvent::Handle',
);

has stream_to_fd => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{} },
);

sub _read_event {
    my $self = shift;
    my $h = shift;

    $h->push_read(json => sub {
        my ($h, $data) = @_;
        if ($data->{notice}) {
            $self->handle_server_notice($h, $data);
        }
        elsif ($data->{response}) {
            $self->handle_server_response($h, $data);
        }
    });
}

sub _ask_for_stream_list {
    my $self = shift;
    my $h    = shift;

    $h->push_write(
        json => +{request => 'sessions'}
    );
}

sub handle_server_notice {
    my $self = shift;
    my $h    = shift;
    my $data = shift;

    if ($data->{notice} eq 'connect') {
        my $conn_data = $data->{connection};
        $self->make_stream(%$conn_data);
    }
    elsif ($data->{notice} eq 'disconnect') {
        my $stream = $data->{session_id};
        my $fd     = $self->stream_to_fd->{$stream};

        $self->delete_stream($fd);
    }
}

sub handle_server_response {
    my $self = shift;
    my $h    = shift;
    my $data = shift;

    if ($data->{response} eq 'sessions') {
        my @sessions = @{ $data->{sessions} };
        if (@sessions) {
            $self->clear_streams;

            foreach my $conn_data (@sessions) {
                $self->make_stream(%$conn_data);
            }
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
        connections => $self,
    );

    if ($args{geometry}) {
        @params{'cols', 'lines'} = @{$args{geometry}};
    }

    #use Data::Dumper::Concise; warn Dumper(\%params);
    my $stream = App::Termcast::Server::Web::Stream->new(%params);

    $stream->connect($args{socket});
}

sub get_stream {
    my $self      = shift;
    my $stream_id = shift;

    my $fd = $self->stream_to_fd->{$stream_id};
    return $self->streams->{$fd};
}

sub vivify_connection {
    my $self = shift;

    require Cwd;
    tcp_connect 'unix/', Cwd::abs_path($self->tc_socket), sub {
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
