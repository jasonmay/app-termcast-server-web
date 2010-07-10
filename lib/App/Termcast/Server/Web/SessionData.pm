#!/usr/bin/env perl
package App::Termcast::Server::Web::SessionData;
use Moose::Role;

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has html_generator => (
    is        => 'ro',
    isa       => 'HTML::FromANSI',
    lazy_build => 1,
);

sub _build_html_generator {
    my $self = shift;
    return HTML::FromANSI->new(
        cols => 80,
        rows => 24,
        tt   => 0,
        wrap => 1,
        show_cursor => 1,
        font_face => 'monaco, consolas, lucida console, monospace',
        style => 'padding: 0; margin: 0;letter-spacing: 0; font-size: 80%; background-color: white',
    );
}

no Moose::Role;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

