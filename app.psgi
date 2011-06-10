use strict;
use warnings;

use blib;
use lib 'lib', '../app-termcast-connector/lib';
use App::Termcast::Server::Web;

App::Termcast::Server::Web->new->to_app;
