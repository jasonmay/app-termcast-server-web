#!/usr/bin/env perl
package App::Termcast::Server::Web::Handler::Socket;
use base qw(Tatsumaki::Handler);
use strict;
use warnings;

use AnyEvent::Socket;
use App::Termcast::Server::Web;
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

    my $web = $self->server;

    my $handle = $web->get_stream_handle($stream_id)
        or return response(
            q|<script language="javascript">window.location = '/';</script>|
        );

    my $updates = $handle->session->update_screen;
    my $screen  = $handle->session->screen;

    if ($type eq 'fresh') {
        $self->write(JSON::encode_json({fresh => $screen}));
    }
    elsif ($type eq 'diff') {
        $self->write(JSON::encode_json({diff => $updates}));
    }

    $self->finish;
}

1;
