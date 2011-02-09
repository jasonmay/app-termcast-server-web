use inc::Module::Install;

name           'App-Termcast-Server-Web';
all_from       'lib/App/Termcast/Server/Web.pm';

build_requires 'Test::More';

requires 'Plack';
requires 'Web::Hippie';
requires 'AnyMQ';
requires 'Moose';
requires 'Path::Dispatcher';
requires 'Path::Dispatcher::Declarative';
requires 'Bread::Board';
requires 'Set::Object';
requires 'AnyEvent';
requires 'Template';
requires 'Term::VT102';

auto_install();
WriteAll();
