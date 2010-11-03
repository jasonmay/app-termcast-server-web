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

my %latest;
sub get {
    my ($self, $stream_id, $type) = @_;

    my $client_id = $self->request->param('client_id')
            or Tatsumaki::Error::HTTP->throw(500, "'client_id' needed");

    $latest{$client_id} ||= 0;
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
            shift(@_) until !@_ or $_[0]->{time} >= $latest{$client_id};
            $self->stream_write(
                [
                    {
                        data => {
                            diff => $self->_squash_events(
                                map { $_->{data}->{diff} } @_
                            )
                        }
                    }
                ]
            );
            $sent = 1;
        }
    );


    if (!$sent) {
        $self->stream_write([]);
    }

    $self->finish();
}

# TODO this is the long way. when feeling more awake,
# just start from the end and assign unless defined
# as opposed to overwrite over and over
sub _squash_events {
    my $self = shift;
    my @events = @_;
    warn scalar(@events);

    my %cells;
    my @results;

    return \@events if scalar(@events) == 1;

    foreach my $diff (map { @$_ } @events) {
        my ($x, $y, $data) = @$diff;
        foreach my $attr (keys %$data) {
            $cells{$x}->{$y}->{$attr} = $data->{$attr};
        }
    }

    foreach my $x (keys %cells) {
        foreach my $y (keys %{ $cells{$x} }) {
            push @results, [$x, $y, $cells{$x}->{$y}];
        }
    }

    return \@results;
}

1;
