use inc::Module::Install;

name           'App-Termcast-Server-Web';
all_from       'lib/App/Termcast/Server/Web.pm';

build_requires 'Test::More';

requires 'Plack';
requires 'Web::Hippie';
requires 'Twiggy';
requires 'EV'; # needs to be installed to work around a current TWiggy bug (3/7)
requires 'Moose';
requires 'Set::Object';
requires 'AnyEvent';
requires 'DateTime::Format::Human::Duration';
requires 'Template';
requires 'Term::VT102::Incremental' => '0.05';

requires 'DateTime';

requires 'YAML';

auto_install();
WriteAll();
