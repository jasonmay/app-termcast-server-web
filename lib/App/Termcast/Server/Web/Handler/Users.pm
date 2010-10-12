#!/usr/bin/env perl
package App::Termcast::Server::Web::Handler::Users;
use base qw(Tatsumaki::Handler);
use strict;
use warnings;

use App::Termcast::Server::Web::Handler::Socket;

use Template;

# XXX use $self->render
my $t = Template->new(
    {
        INCLUDE_PATH => 'web/tt',
    }
);

sub get {
    my $self = shift;

    my $socket_handler_class = 
        'App::Termcast::Server::Web::Handler::Socket';

    my $web = $socket_handler_class->server;

    my %config = (
        stream_data => $web->stream_data,
    );

    $t->process('users.tt', \%config, \my $output)
        or die $t->error();

    $self->write($output);
}

1;
