package App::Termcast::Server::Web::Hippie::Root;
use Moose;

has connections => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::Web::Connections',
    required => 1,
);

sub new_listener {
    my $self = shift;
    my ($r) = @_;

    my $h         = $r->env->{'hippie.handle'};
    my $stream_id = $r->env->{'hippie.args'};

    my $stream = $self->connections->get_stream($stream_id);

    my $hh = App::Termcast::Server::Web::Hippie::Handle->new(
        stream => $stream_id,
        handle => $h,
        lines  => $stream->lines,
        cols   => $stream->cols,
    );

    if ($h->isa('Web::Hippie::Handle::WebSocket')) {
        weaken(my $weak_hippie = $hh);
        $h->h->on_error(
            sub {
                $self->connections->hippie_handles->remove($weak_hippie);
            }
        );
    }

    $self->connections->hippie_handles->insert($hh);

    # send buffer to get the viewer caught up
    $hh->send_to_browser($stream->buffer);

    my $res = $r->new_response(200);
    $res->content_type('application/hippie');
    return $res;
}

sub error {
    my $self = shift;
    my ($r) = @_;
    my $h = $r->env->{'hippie.handle'};

    $self->hippie->handles->remove($h) if $h;
}

no Moose;

1;
