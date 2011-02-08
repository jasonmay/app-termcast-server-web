package App::Termcast::Server::Web::Stream;
use Moose;

use AnyEvent::Socket;
use Time::HiRes;

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

sub connect {
    my $self = shift;
    my $socket = shift;

    tcp_connect 'unix/', $socket, sub {
        my $fh = shift;
        my $handle = AnyEvent::Handle->new(
            fh => $fh,
            on_read => sub {
                my $h = shift;

                my @hh = $self->connections->hippie->hippie_handles->members;
                $h->{rbuf} =~ s/.\e\[2J/\e\[H\e\[2J/s;
                foreach my $hippie_handle (@hh) {
                    if ($h->{rbuf} =~ /\e\[2J/s) {
                        $hippie_handle->clear_vt;
                    }


                    $hippie_handle->send_to_browser($h->rbuf);

                }
                $h->{rbuf} = '';

            },
            on_error => sub {
                my ($h, $fatal, $error) = @_;
                if ($fatal) {
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
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
