package App::Termcast::Server::Web::VT102i;
use Moose;
extends 'Term::VT102::Incremental';

use constant vt_class => 'App::Termcast::Server::Web::VT102';

__PACKAGE__->meta->make_immutable;
no Moose;

1;
