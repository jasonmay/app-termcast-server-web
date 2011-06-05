package App::Termcast::Server::Web;
use XSLoader;
use OX;

use Plack::Request;
use Plack::Middleware::Static;

use Template;

use YAML;
use Path::Class 'dir';
use MooseX::Types::UUID 'UUID';
use MooseX::Types::Path::Class;

with 'OX::Role::WithAppRoot';

has tt_root => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    lifecycle => 'Singleton',
    coerce    => 1,
    block     => sub { shift->param('app_root')->subdir('web', 'tt') },
    dependencies => ['app_root'],
);

has tt => (
    is => 'ro',
    isa => 'Template',
    block => sub {
        my $service = shift;
        return Template->new(INCLUDE_PATH => $service->param('tt_root'));
    },
    dependencies => ['tt_root'],
);

has config => (
    is        => 'ro',
    lifecycle => 'Singleton',
    block     => sub {
        my $file = shift->param('app_root')->subdir('etc')->file('config.yml');
        return YAML::LoadFile($file->stringify);
    },
    dependencies => ['app_root'],
);

has connections    => (
    is           => 'ro',
    isa          => 'App::Termcast::Server::Web::Connections',
    lifecycle    => 'Singleton',
    dependencies => ['config'],
);

has tv => (
    is           => 'ro',
    isa          => 'App::Termcast::Server::Web::TV',
    lifecycle    => 'Singleton',
    dependencies => ['connections', 'tt', 'config'],
);

#has hippie_mw => (
#    is           => 'ro',
#    isa          => 'App::Termcast::Server::Web::Hippie::MW',
#    lifecycle    => 'Singleton',
#    dependencies => ['connections', 'tt', 'config'],
#);

sub build_middleware {
        [
            Plack::Middleware::Static->new(
                path => qr!^/?(?:static/|favicon\.ico)!,
                root => 'web/',
            ),
        ]
}

router as {
    route '/'       => 'tv.users';
    route '/tv/:id' => 'tv.view',
        id => { isa => UUID };

    mount '/_hippie' => 'App::Termcast::Server::Web::Hippie' => (
        connections => 'connections',
    );
}, (tv => 'tv');

XSLoader::load(__PACKAGE__);
no Moose;

1;
