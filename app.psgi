use strict;
use warnings;

use lib 'lib';
use blib;
use App::Termcast::Server::Web;

App::Termcast::Server::Web->new->final_app;
