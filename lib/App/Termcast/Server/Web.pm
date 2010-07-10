#!::usr::bin::env perl
package App::Termcast::Server::Web;

use Twiggy::Server;
use Plack::Request;
use Plack::Response;
use Plack::Builder;

use App::Termcast::Session;
use App::Termcast::Handle;
use AnyEvent::Socket;

use App::Termcast::Server::Web::Dispatcher;
use Path::Dispatcher::Path;

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

has server => (
    is      => 'rw',
    isa     => 'Twiggy::Server',
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
        or die "localhost connect failed: $!";

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

sub handle_server_notice {
    my $self = shift;
    my $data = shift;

    if ($data->{notice} eq 'connect') {
        $self->set_stream(
            $data->{connection}{session_id} => $data->{connection},
        );

        $self->create_stream_handle(
            $data->{connection}{session_id},
            $data->{connection}{socket},
        );
    }
    elsif ($data->{notice} eq 'disconnect') {
        $self->delete_stream($data->{session_id});
        $self->delete_stream_handle($data->{session_id});

    }
}

sub handle_server_response {
    my $self = shift;
    my $data = shift;

    if ($data->{response} eq 'sessions') {
        my @sessions = @{ $data->{sessions} };
        if (@sessions) {
            $self->clear_stream_handles;
            $self->clear_stream_data;
            for (@sessions) {
                $self->set_stream($_->{session_id} => $_);
                $self->create_stream_handle($_->{session_id}, $_->{socket});
            }
        }
    }
}

sub create_stream_handle {
    my $self       = shift;
    my $session_id = shift;
    my $socket     = shift;

    tcp_connect 'unix/', $socket, sub {
        my $fh = shift;
        my $h = App::Termcast::Handle->new(
            fh => $fh,
            on_read => sub {
                my $h = shift;
                $h->push_read(
                    chunk => 1, sub {
                        my ($h, $char) = @_;
                        $h->session->html_generator->add_text(
                            $char
                        );
                    },
                );
            },
            on_error => sub {
                my ($h, $fatal, $error) = @_;
                if ($fatal) {
                    $self->delete_stream_handle($h->session_id);
                    $h->destroy;
                }
                else {
                    warn $error;
                }
            },
            handle_id => $session_id,
        );

        my $session = App::Termcast::Session->with_traits(
            'App::Termcast::Server::Web::SessionData'
        )->new();
        $h->session($session);
        $self->set_stream_handle($h->handle_id => $h);
    };

}

sub run {
    my $self = shift;

    my $server = Twiggy::Server->new(
        port => $self->port,
    );

    $server->register_service($self->app);
    $self->server($server);

    tcp_connect $self->host, $self->client_port, sub {
        $self->client_connect(@_);
    };
    AE::cv->recv;
}

sub app {
    my $self = shift;

    builder {
        enable 'Plack::Middleware::Static',
            path => sub { s!^/static/!! }, root => 'web/';

        sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $path = Path::Dispatcher::Path->new(
                path     => $req->path_info,
                metadata => $req->env,
            );

            my $dispatch = App::Termcast::Server::Web::Dispatcher->dispatch($path);
            return Plack::Response->new(404)->finalize if !$dispatch->has_matches;

            $dispatch->run($req, $self);
        };
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and::or modify it under the same terms as Perl itself.

