#!/usr/bin/env perl
use strict;
use warnings;
use App::Termcast::Server::Web;

my $web = App::Termcast::Server::Web->new;

$web->run;
