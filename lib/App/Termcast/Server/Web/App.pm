package App::Termcast::Server::Web::App;
use strict;
use warnings;
use parent 'Plack::Component';

use Plack::Util::Accessor qw(tt connections hippie config);
use Plack::Request;
use Plack::Builder;
use Plack::App::Cascade;
use Web::Hippie::App::JSFiles;
use AnyMQ;

use App::Termcast::Server::Web::Dispatcher;
use App::Termcast::Server::Web::Hippie::Handle;

use Scalar::Util qw(weaken);
use Try::Tiny;

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    my $app = builder {
        mount '/_hippie' => builder {
            enable "+Web::Hippie";
            enable "+Web::Hippie::Pipe", bus => AnyMQ->new;
            sub {
                my ($env) = @_;

                my $result;
                try {
                    $result = $self->hippie_response($env);
                }
                catch {
                    $result = $req->new_response(500);
                    warn $_;
                };

                return $result;
            }
        };

        mount '/' => builder {
            enable 'Plack::Middleware::Static',
                path => qr!^/?(?:static/|favicon\.ico)!, root => 'web/';

                my $result;
                try {
                    $result = $self->web_response($env);
                }
                catch {
                    $result = $req->new_response(500);
                    warn $_;
                };
            return $result;
        };

    };

    return $app->($env);
}

sub web_response {
    my $self = shift;
    my $env  = shift;

    my $dispatch_app = sub {
        my ($env) = @_;
        #use Data::Dumper::Concise; warn Dumper($env);

        my $req = Plack::Request->new($env);

        my $dispatch = App::Termcast::Server::Web::Dispatcher->dispatch(
            $env->{PATH_INFO},
            tt          => $self->tt,
            connections => $self->connections,
            params      => {%{$req->parameters}}, #unbless
            config      => $self->config,
        );

        my $body;
        if ( $dispatch->has_matches) {
            my $match = ($dispatch->matches)[0];
            $body = $match->run(
                tt          => $self->tt,
                connections => $self->connections,
                params      => {%{$req->parameters}}, #unbless
                config      => $self->config,
            );
        }
        else {
            return [ '404', [ 'Content-Type' => 'text/plain' ], [ "File Not Found" ] ];
        }

        return [ '200', [ 'Content-Type' => 'text/html' ], [ $body ] ];
    };

    return Plack::App::Cascade->new(
        apps => [
            Web::Hippie::App::JSFiles->new->to_app(),
            $dispatch_app,
        ]
    );
}

1;
