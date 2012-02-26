package App::Termcast::Server::Web;
use XSLoader;
use OX;

use Plack::Request;
use Plack::Middleware::Static;

use Template;

use YAML;
use Path::Class 'dir';
use MooseX::Types::Path::Class;

use Path::Class::File;

has app_root => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    lifecycle => 'Singleton',
    coerce    => 1,
    block     => sub { Path::Class::File->new(__FILE__)->parent->parent->parent->parent->parent },
);

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
        return Template->new(
            INCLUDE_PATH => $service->param('tt_root'),
            WRAPPER      => 'wrapper.tt',
        );
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

sub build_middleware {
        [
            Plack::Middleware::Static->new(
                path => qr!^/?(?:static/|favicon\.ico)!,
                root => 'web/',
            ),
        ]
}

sub BUILD { shift->connections->vivify_connection }

sub streams_uri { '/streams' }

router as {
    route '/'       => sub {
        my $res    = $_[0]->new_response;
        my $prefix = $_[0]->script_name;
        $res->redirect($prefix . streams_uri() );
        return $res;
    };
    route streams_uri() => 'tv.users';
    route '/about'       => 'tv.about';
    route '/tv/:id' => 'tv.view',
        id => { isa => 'Str' };

    mount '/_hippie' => 'App::Termcast::Server::Web::Hippie' => (
        connections => 'connections',
    );
    mount '/hippiejs' => 'Web::Hippie::App::JSFiles';
}, (tv => 'tv');

XSLoader::load(__PACKAGE__);
no Moose;

1;
