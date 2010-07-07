#!::usr::bin::env perl
package App::Termcast::Server::Web;
use Moose;
use Twiggy::Server;
use namespace::autoclean;

=head1 NAME

App::Termcast::Server::Web -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 7071,
    lazy    => 1,
);

has server => (
    is      => 'ro',
    isa     => 'Twiggy::Server',
    builder => '_build_server',
);

sub _build_server {
    my $self = shift;

    my $server = Twiggy::Server->new(
#        host => $self->host,
        port => $self->port,
    );

    $server->register_service(sub { $self->handle_http(@_) });
    warn $server;

    return $server;
}

sub handle_http {
    my $self = shift;
    my $env  = shift;

    return[200, ["Content-Type" => 'text/html'], [''] ];
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

