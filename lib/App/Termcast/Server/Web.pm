#!::usr::bin::env perl
package App::Termcast::Server::Web;
use Moose;
use AnyEvent::Socket;
use Twiggy::Server;
use App::Termcast::Session;
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
    },
);

sub BUILD {
    my $self = shift;

    my $server = Twiggy::Server->new(
#        host => $self->host,
        port => $self->port,
    );

    $server->register_service(sub { $self->handle_http(@_) });
    $self->server($server);

    tcp_connect $self->host, $self->client_port, sub {
        $self->client_connect(@_);
    };

}

sub handle_http {
    my $self = shift;
    my $env  = shift;

    require YAML;
    my $dump = YAML::Dump($self->stream_data);

    return[200, ["Content-Type" => 'text/plain'], [$dump] ];
}

sub client_connect {
    my $self = shift;
    my ($fh) = @_
        or die "localhost connect failed: $!";

    warn "client connect";
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
    }
    elsif ($data->{notice} eq 'disconnect') {
        $self->delete_stream($data->{session_id});
    }
    $self->send_connection_list($_) for $self->handle_list;
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
                tcp_connect 'unix/', $_->{socket}, sub {
                    my $fh = shift;
                    my $u_h = App::Termcast::Handle->new(
                        fh => $fh,
                        on_read => sub {

                        },
                        on_error => sub {
                            my ($u_h, $fatal, $error) = @_;
                            $self->delete_stream_handle($u_h->session_id);
                            $u_h->destroy;
                        },
                        session_id => $_->{session_id},
                    );

                    my $session = App::Termcast::Session->with_traits(
                        'App::Termcast::Server::Web::SessionData'
                    )->new();
                    $u_h->session($session);
                };
            }
        }
    }
}
sub run {
    AE::cv->recv;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and::or modify it under the same terms as Perl itself.

