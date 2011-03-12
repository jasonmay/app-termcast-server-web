package App::Termcast::Server::Web::Stream;
use Moose;

use DateTime;

use AnyEvent::Socket;

use Term::VT102::Incremental;


has handle => (
    is       => 'rw',
    isa      => 'AnyEvent::Handle',
);

has connections => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::Web::Connections',
    required => 1,
    weak_ref => 1,
);

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has buffer => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
);

has cols => (
    is       => 'rw',
    isa      => 'Num',
    default  => 80,
);

has lines => (
    is       => 'rw',
    isa      => 'Num',
    default  => 24,
);

has last_active => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now() },
);

sub connect {
    my $self = shift;
    my $socket = shift;

    tcp_connect 'unix/', $socket, sub {
        my $fh = shift;
        my $handle = AnyEvent::Handle->new(
            fh => $fh,
            on_read => sub {
                my $h = shift;
                #warn "$h->{rbuf}\n";

                my @hh = $self->connections->hippie->hippie_handles->members;
                my $cleared = 0;
                if ($h->{rbuf} =~ s/.\e\[2J//s) {
                    $self->buffer('');
                    $cleared = 1;
                }

                my $buf = ($cleared ? "\e[H\e[2J" : '') . $h->{rbuf};
                foreach my $hippie_handle (@hh) {
                    next unless $hippie_handle->stream eq $self->id;
                    if ($buf =~ /\e\[2J/s) {
                        $hippie_handle->clear_vt;
                        $hippie_handle->send_clear_to_browser();
                    }

                    #warn length($buf);
                    $hippie_handle->send_to_browser($buf);
                }

                $self->mark_active();
                $self->{buffer} .= $h->{rbuf};
                $h->{rbuf} = '';

            },
            on_error => sub {
                my ($h, $fatal, $error) = @_;
                if ($fatal) {

                    my $stream = $self->connections->streams->{ fileno($h->fh) };

                    my @hh = $self->connections->hippie->hippie_handles->members;

                    foreach my $hh ( @hh ) {
                        next unless $hh->stream eq $stream->id;
                        $hh->send_disconnect_to_browser();
                    }

                    $self->connections->delete_stream( fileno($h->fh) );
                    $h->destroy;
                }
                else {
                    warn $error;
                }
            },
        );

        my $fd = fileno($handle->fh);
        $self->handle($handle);
        $self->connections->set_stream(
            $fd => $self,
        );

        $self->connections->stream_to_fd->{$self->id} = $fd;

        if (my $notices_ref = delete $self->connections->notice_buffer->{$self->id}) {
            foreach my $notice_data (@$notices_ref) {
                $self->connections->handle_server_notice($notice_data);
            }
        }
    };
}

sub mark_active { shift->last_active(DateTime->now) }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
