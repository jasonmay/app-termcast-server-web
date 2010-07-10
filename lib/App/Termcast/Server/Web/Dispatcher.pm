#!/usr/bin/env perl
package App::Termcast::Server::Web::Dispatcher;

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

use Path::Dispatcher::Declarative -base, -default => {
    token_delimiter => '/',
};

on qr{^/$} => sub { [200, ['Content-Type', 'text/plain'], ['index']] };

under { REQUEST_METHOD => 'GET' } => sub {
    on ['socket'] => sub {
        my $req = shift;
        my $web = shift;

        my $s = $req->param('stream');
        [200, ['Content-Type', 'text/plain'], ['testing']];
    };
};

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

