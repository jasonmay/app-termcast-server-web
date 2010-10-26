#!/usr/bin/env perl
package App::Termcast::Server::Web::SessionData;
use Moose::Role;
use Term::VT102;

=head1 NAME

Foo -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has cols => (
    is      => 'ro',
    isa     => 'Int',
    default => 80,
);

has rows => (
    is      => 'ro',
    isa     => 'Int',
    default => 24,
);

has vt => (
    is         => 'ro',
    isa        => 'Term::VT102',
    lazy_build => 1,
);

has screen => (
    is        => 'ro',
    isa       => 'ArrayRef[ArrayRef[HashRef]]', # lol
    default   => sub {
        my $self = shift;
        my ($rows, $cols) = ($self->rows, $self->cols);

        return [
            map {
            [ map { +{} } (1 .. $cols) ]
            } (1 .. $rows)
        ];
    },
);

sub _build_vt {
    my $self = shift;
    return Term::VT102->new(
        cols => $self->cols,
        rows => $self->rows,
    );
}

sub update_screen {
    my $self = shift;
    my ($vt, $screen) = ($self->vt, $self->screen);

    my %updates;
    my @data;
    foreach my $row (0 .. $self->rows-1) {
        my $line = $vt->row_plaintext($row + 1);
        my $att = $vt->row_attr($row + 1);

        foreach my $col (0 .. $self->cols-1) {
            my $text = substr($line, $col, 1);

            $text = ' ' if ord($text) == 0;

            my %data;

            @data{qw|fg bg bo fo st ul bl rv v|}
                = ($vt->attr_unpack(substr($att, $col * 2, 2)), $text);

            my $prev = $screen->[$row]->[$col];
            $screen->[$row]->[$col] = {%data}; # clone

            if ($prev) {
                foreach my $attr (keys %data) {
                    delete $data{$attr}
                        if #$prev->{$attr} and
                        ($data{$attr} || '') eq ($prev->{$attr} || '');
                }
            }

            push @data, [$row, $col, \%data] if scalar(keys %data) > 0;
        }
    }

    return \@data;
}

no Moose::Role;

1;

__END__

=head1 METHODS


=head1 AUTHOR

Jason May C<< <jason.a.may@gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

