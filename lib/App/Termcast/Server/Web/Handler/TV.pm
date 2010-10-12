#!/usr/bin/env perl
package App::Termcast::Server::Web::Handler::TV;
use base qw(Tatsumaki::Handler);
use strict;
use warnings;

use App::Termcast::Server::Web::Handler::Socket;

# XXX use $self->render
my $t = Template->new(
    {
        INCLUDE_PATH => 'web/tt',
    }
);

sub get {
    my ($self, $stream_id) = @_;

    my $web = App::Termcast::Server::Web::Handler::Socket->server;

    my $vars = {
        stream_id => $stream_id,
    };

    $t->process('viewer.tt', $vars, \my $output) or die $t->error();

    $self->write($output);
}

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

