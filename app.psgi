use strict;
use warnings;

use lib 'lib';
use App::Termcast::Server::Web;


my $socket;
for (0 .. @ARGV-1) {
    if ($ARGV[$_] eq '--tc-socket') {
        $socket = $ARGV[$_+1];
        last;
    }
}

App::Termcast::Server::Web->new(tc_socket => $socket)->final_app;
