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

             if (!$latest{$client_id}) {
                 #send the entire screen for foundation
                 my $screen = $handle->session->screen;

                 my @cells;

                 foreach my $x (0 .. @$screen - 1) {
                     foreach my $y (0 .. @{$screen->[$x]} - 1) {
                         my $data = $screen->[$x]->[$y];
                         next unless $data;
                         next unless scalar(keys %$data);

                         next if !$data->{v};
                         next if $data->{v} eq ' ' and !$data->{bg};

                         $data->{bo} = 0; # experiment
                         push @cells, [$x, $y, $data];
                     }
                 }
                 unshift @_, +{data => \@cells};
             }

            my $data = $self->_squash_events( map { $_->{data} } @_ );
            $self->stream_write( [{data => $data}] );
            $sent = 1;

            $latest{$client_id} = $_[-1]->{time};
        }
    );


    if (!$sent) {
        $self->stream_write([]);
    }

    $self->finish();
}

sub _squash_events {
    my $self = shift;
    my @events = @_;

    my %cells;
    my @results;

    #require JSON; warn JSON::encode_json(
    #    [
    #        map { [$_->[0], $_->[1], $_->[2]->{v}] }
    #        grep { defined $_->[2]->{v} }
    #        map { @$_ } @events
    #    ]
    #);
    return $events[0] if scalar(@events) == 1;

    foreach my $diff (map { @$_ } reverse @events) {
        my ($x, $y, $data) = @$diff;
        while (my ($attr, $value) = each %$data) {
            if (!exists $cells{$x}->{$y}->{$attr}) {
                $cells{$x}->{$y}->{$attr} = $value;
            }
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
