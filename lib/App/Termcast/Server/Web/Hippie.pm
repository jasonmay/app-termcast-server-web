package App::Termcast::Server::Web::Hippie;
use OX;
use Web::Hippie;
use Web::Hippie::Pipe;
use AnyMQ;

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
    ];
}

router as {
    route '/:action' => 'root._';
}, (root => 'root');

no Moose;

1;
