package App::Termcast::Server::Web::Hippie;
use OX;

use Web::Hippie;
use Web::Hippie::Pipe;
use Web::Hippie::App::JSFiles;
use AnyMQ;

use Plack::Util;

use Try::Tiny;

has connections => (
    is      => 'ro',
    isa     => 'App::Termcast::Server::Web::Connections',
    required => 1,
);

has root => (
    is    => 'ro',
    isa   => 'App::Termcast::Server::Web::Hippie::Root',
    infer => 1,
);

sub build_middleware {
    [
        Web::Hippie->new,
        Web::Hippie::Pipe->new(bus => AnyMQ->new),
#        sub {
#            my $app = shift;
#            sub {
#                my $env = shift;
#                my $res =  $app->($env);
#
#                return Plack::Util::response_cb(
#                    $res, sub {
#                        my $res = shift;
#                        warn "200 THIS SHIT";
#                        if ($res->[0] != 200) {
#                            return [
#                                200,
#                                ['Content-Type' => 'application/hippie'],
#                                ['']
#                            ];
#                        }
#                    },
#                );
#            };
#        },
    ];
}

router as {
    route '/new_listener' => 'root.new_listener';
    route '/error' => 'root.error';

    mount '/files' => 'Web::Hippie::App::JSFiles';
}, (root => 'root');

no Moose;

1;
