package App::Termcast::Server::Web::App;
use strict;
use warnings;
use parent 'Plack::Component';

use Plack::Util::Accessor qw(tc_socket tt connections);
use Plack::Builder;
use AnyMQ;

use App::Termcast::Server::Web::Dispatcher;

sub call {
    my ($self, $env) = @_;

    my $app = builder {
        mount '/_hippie' => builder {
            enable "+Web::Hippie";
            enable "+Web::Hippie::Pipe", bus => AnyMQ->new;
            sub {
                my ($env) = @_;

                if ($env->{PATH_INFO} eq '/new_listener') {
                    warn "NEW LIESTENRENR";
                }
                else {
                    warn "NOT NEW LIESTENRENR";
                }
                return [ '200', [ 'Content-Type' => 'application/hippie' ], [ "" ] ]
            }
        };

        mount '/' => builder {
            enable 'Plack::Middleware::Static',
                path => qr!^/?static/!, root => 'web/';

            sub {
                my ($env) = @_;
                #use Data::Dumper::Concise; warn Dumper($env);

                warn $self->tt;
                my $dispatch = App::Termcast::Server::Web::Dispatcher->dispatch(
                    $env->{PATH_INFO},
                    tt          => $self->tt,
                    connections => $self->connections,
                );

                my $body;
                if ( $dispatch->has_matches) {
                    my $match = ($dispatch->matches)[0];
                    $body = $match->run(
                        tt          => $self->tt,
                        connections => $self->connections,
                    );
                }
                else {
                    $body = "nobody";
                }

                return [ '200', [ 'Content-Type' => 'text/html' ], [ $body ] ];
            }
        };

    };

    return $app->($env);
}

1;
