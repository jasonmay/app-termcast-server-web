package App::Termcast::Server::Web::Hippie::Root;
use Moose;

use App::Termcast::Server::Web::Hippie::Handle;
use Scalar::Util 'weaken';

has connections => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::Web::Connections',
    required => 1,
);

sub init {
    my $self = shift;
    my ($r) = @_;

    my $h = $r->env->{'hippie.handle'} or do {
        my $res = $r->new_response(400);
        $res->content_type('text/plain');
        return $res;
    };

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

    return $self->misc(@_);
}

sub error {
    my $self = shift;
    my ($r) = @_;
    my $h = $r->env->{'hippie.handle'};

    $self->connections->hippie_handles->remove($h) if $h;
}

sub misc {
    my $self = shift;
    my ($r) = @_;

    my $res = $r->new_response(200);
    $res->content_type('application/hippie');
    $res->body('');

    return $res->finalize;
}

no Moose;

1;
