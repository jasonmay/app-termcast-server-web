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

my $t = Template->new(
    {
        INCLUDE_PATH => 'web/tt',
    }
);

my $json = JSON->new;

on qr{^/$} => sub {
    my $req = shift;
    my $web = shift;

    my $output;

    my %config = (
        stream_data => $web->stream_data,
    );

    $t->process('users.tt', \%config, \$output)
        or die $t->error();

    my $res = response($output);
    return $res;
};

under { REQUEST_METHOD => 'GET' } => sub {
    on ['socket', qr|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$|, qr/^\w+$/] => sub {
        my $req = shift;
        my $web = shift;

        my $output;
        my ($stream, $type) = ($2, $3);

        my $handle = $web->get_stream_handle($stream)
            or return response(
                q|<script language="javascript">window.location = '/';</script>|
            );

        my $updates = $handle->session->update_screen;
        my $screen = $handle->session->screen;

        if ($type eq 'fresh') {
            return response($json->encode({fresh => $screen}));
        }
        elsif ($type eq 'diff') {
            return response($json->encode({diff => $updates}));
        }

    };
};

under { REQUEST_METHOD => 'GET' } => sub {
    on ['view', qr|^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$|] => sub {
        my $req = shift;
        my $web = shift;

        my $output;
        my $stream = $2;

        my $vars = {
            stream_id => $stream,
        };

        $t->process('viewer.tt', $vars, \$output) or die $t->error();

        return response($output);
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

