use Tatsumaki::Application;
use Plack::Builder;
use Plack::Middleware::Static;
use Class::MOP;

use lib 'lib';
use lib 'server/lib'; # XXX
use App::Termcast::Server::Web::Handler::Users;
use App::Termcast::Server::Web::Handler::ID;
use App::Termcast::Server::Web::Handler::Socket;

sub handler {
    my $class = 'App::Termcast::Server::Web::Handler::' . $_[0];
    Class::MOP::load_class($class);
    return $class;
}

my $uuid_re = '([\w-]+)';
my $type_re = '(\w+)';
my $app = Tatsumaki::Application->new(
    [
        '/'                         => handler('Users'),
        '/id'                       => handler('ID'),
        "/socket/$uuid_re/$type_re" => handler('Socket'),
        "/view/$uuid_re"            => handler('TV'),
    ],
);

builder {
    enable 'Plack::Middleware::Static',
        path => qr!^/?static/!, root => 'web/';

    $app;
};
