use strict;
use warnings;

use blib;
use lib 'lib';
use App::Termcast::Server::Web;

App::Termcast::Server::Web->new->to_app;
