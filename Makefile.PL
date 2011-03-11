use inc::Module::Install;

name           'App-Termcast-Server-Web';
all_from       'lib/App/Termcast/Server/Web.pm';

build_requires 'Test::More';

requires 'Plack';
requires 'Web::Hippie';
requires 'Twiggy';
requires 'EV'; # needs to be installed to work around a current TWiggy bug (3/7)
requires 'AnyEvent';
requires 'AnyMQ';
requires 'Moose';
requires 'Path::Dispatcher';
requires 'Path::Dispatcher::Declarative';
requires 'Bread::Board' => '0.15';
requires 'Set::Object';
requires 'AnyEvent';
requires 'Template';
requires 'Term::VT102::Incremental';

requires 'DateTime';

auto_install();
WriteAll();
