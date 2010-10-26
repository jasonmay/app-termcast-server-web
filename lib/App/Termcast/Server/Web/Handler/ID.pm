#!/usr/bin/env perl
package App::Termcast::Server::Web::Handler::ID;
use base qw(Tatsumaki::Handler);
use strict;
use warnings;
use Data::UUID::LibUUID;

sub get {
    my $self = shift;

    $self->write(new_uuid_string());
}

1;
