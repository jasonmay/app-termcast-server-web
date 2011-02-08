#!/usr/bin/env perl
package App::Termcast::Server::Web;

use Tatsumaki::MessageQueue;
$Tatsumaki::MessageQueue::BacklogLength = 10;

use Plack::Request;
use Plack::Response;
use Plack::Builder;

use App::Termcast::Session;
use App::Termcast::Handle;
use AnyEvent::Socket;

use Time::HiRes;

#use File::Temp qw(tempfile);

use Moose;

use namespace::autoclean;

=head1 NAME

App::Termcast::Server::Web -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => 'localhost',
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 7071,
);

has client_port => (
    is      => 'ro',
    isa     => 'Int',
    default => 9092,
);

has client_handle => (
    is  => 'rw',
    isa => 'AnyEvent::Handle',
);

has stream_data => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { +{} },
    handles => {
        set_stream         => 'set',
        stream_ids         => 'keys',
        get_stream         => 'get',
        delete_stream      => 'delete',
        clear_stream_data  => 'clear',
    },
);

has stream_handles => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { +{} },
    handles => {
        set_stream_handle    => 'set',
        stream_handle_ids    => 'keys',
        get_stream_handle    => 'get',
        stream_handle_list   => 'get',
        delete_stream_handle => 'delete',
        clear_stream_handles => 'clear',
    },
);

sub client_connect {
    my $self = shift;
    my ($fh) = @_
        or die $self->host . " connect failed: $!";

    my $h = AnyEvent::Handle->new(
        fh => $fh,
        on_read => sub {
            my ($h, $host, $port) = @_;
            $h->push_read(
                json => sub {
                    my ($h, $data) = @_;
                    if ($data->{notice}) {
                        $self->handle_server_notice($data);
                    }
                    elsif ($data->{response}) {
                        $self->handle_server_response($data);
                    }
                }
            );
        },
        on_error => sub {
            my ($h, $fatal, $error) = @_;
            warn $error;
            exit 1 if $fatal;
        },
    );

    $h->push_write(
        json => +{
            request => 'sessions',
        }
    );

    $self->client_handle($h);
}

sub run {
    my $self = shift;
    tcp_connect $self->host, $self->client_port, sub {
        warn "connected...";
        $self->client_connect(@_);
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

