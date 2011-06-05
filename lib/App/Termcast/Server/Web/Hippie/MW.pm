package App::Termcast::Server::Web::Hippie;
use Moose;
use MooseX::NonMoose;
extends 'Plack::Middleware';

use Web::Hippie;
use Web::Hippie::Pipe;
use AnyMQ;

sub call {
    my ($self, $env) = @_;

    my $app = $self->app;
        $app = Web::Hippie->wrap($app);
        $app = Web::Hippie::Pipe->wrap($app, bus => AnyMQ->new);
        sub {
            my ($env) = @_;

            my $result;
            try {
                $result = $self->hippie_response($env);
            }
            catch {
                $result = $r->new_response(500);
                warn $_;
            };

            return $result;
        }
}


__PACKAGE__->meta->make_immutable;
no Moose;

1;
