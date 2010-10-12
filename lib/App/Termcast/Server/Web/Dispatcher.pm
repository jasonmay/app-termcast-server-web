#!/usr/bin/env perl
package App::Termcast::Server::Web::Dispatcher;
use Template;
use JSON;

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

use Path::Dispatcher::Declarative -base, -default => {
    token_delimiter => '/',
};

my $json = JSON->new;

on qr{^/$} => sub {
    my $req = shift;
    my $web = shift;

    my $output;

};

under { REQUEST_METHOD => 'GET' } => sub {
    on ['socket', qr|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$|, qr/^\w+$/] => sub {
        my $req = shift;
        my $web = shift;

        my $output;
        my ($stream, $type) = ($2, $3);


    };
};

under { REQUEST_METHOD => 'GET' } => sub {
    on ['view', qr|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$|] => sub {
        my $req = shift;
        my $web = shift;

        my $stream = $2;

    };
};

sub response {
    my $message = shift;

    return [200, ['Content-Type', 'text/html'], [$message]];
}

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

