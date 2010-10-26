#!/usr/bin/env perl
package App::Termcast::Server::Web::Handler::Socket;
use base qw(Tatsumaki::Handler);
use strict;
use warnings;

use AnyEvent::Socket;
use App::Termcast::Server::Web;
use Template;
use JSON ();

__PACKAGE__->asynchronous(1);

my $web = App::Termcast::Server::Web->new;
$web->run;

sub server { $web }

my $t = Template->new(
    {
        INCLUDE_PATH => 'web/tt',
    }
);

sub get {
    my ($self, $stream_id, $type) = @_;

    my $client_id = $self->request->param('client_id')
            or Tatsumaki::Error::HTTP->throw(500, "'client_id' needed");

    my $web = $self->server;

    #require JSON; warn JSON::encode_json($web->stream_data);
    my $handle = $web->get_stream_handle($stream_id)
    or do {
        $self->write([]);
        $self->finish;
        return;
    };

    my $mq = Tatsumaki::MessageQueue->instance($stream_id);

    my $sent;
    $mq->poll(
        $client_id, sub {
            $self->write(\@_);
            $sent = 1;
        }
    );


    if (!$sent) {
        $self->write([]);
    }

    $self->finish();
}

1;
