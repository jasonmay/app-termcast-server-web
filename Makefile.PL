use inc::Module::Install;

name           'App::Termcast::Server::Web';
all_from       'lib/App/Termcast/Server/Web.pm';

build_requires 'Test::More';

requires 'Plack';
requires 'Twiggy';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'Path::Dispatcher';
requires 'Path::Dispatcher::Declarative';
requires 'AnyEvent';
requires 'Template';

auto_install();
WriteAll();
