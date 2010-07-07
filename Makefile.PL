use inc::Module::Install;

name           'App::Termcast::Server::Web';
all_from       'lib/App/Termcast/Server/Web.pm';

build_requires 'Test::More';
build_requires 'Twiggy';

auto_install();
WriteAll();
