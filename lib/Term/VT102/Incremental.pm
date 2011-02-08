package Term::VT102::Incremental;
use Moose;
use Term::VT102;

has vt => (
    is      => 'ro',
    isa     => 'Term::VT102',
    handles => ['process', 'rows' ,'cols'],
);

has _screen => (
    is        => 'ro',
    isa       => 'ArrayRef[ArrayRef[HashRef]]',
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

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @vt_args  = @_;

    my $vt = Term::VT102->new(@vt_args);

    return $class->$orig(vt => $vt);
};

sub get_increment {
    my $self = shift;
    my ($vt, $screen) = ($self->vt, $self->_screen);

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

                    # XXX (resource-unfriendly) hack because bold stuff
                    #     is busted right now
                    #if ($attr eq 'bo') {
                    #    if (($data{v} || '') eq ' ') {
                    #        delete $data{bo};
                    #    }
                    #    next;
                    #}

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

__PACKAGE__->meta->make_immutable;
no Moose;

1;
