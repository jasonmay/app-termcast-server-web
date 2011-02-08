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

has vt => (
    is       => 'ro',
    isa      => 'Term::VT102::Incremental',
    default  => sub {
        Term::VT102::Incremental->new
    },

    clearer => 'clear_vt',
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

                if ($h->{rbuf} =~ s/.*\e\[2J//sm) {

                    # reset so its buffer is 100% empty
                    $self->clear_vt;
                }
                $self->vt->process($h->rbuf);

                my $updates = $self->vt->get_increment();

                warn "typety type";
                # TODO send to all the appropriate hippie handles
                my $beepbeepbeepbooooop = {
                    type    => 'message',
                    data    => $updates,
                    time => scalar Time::HiRes::gettimeofday,
                };

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

        $self->handle($handle);
        $self->connections->set_stream(
            fileno($handle->fh) => $self,
        );
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
