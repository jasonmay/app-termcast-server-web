package App::Termcast::Server::Web::Dispatcher;
use Path::Dispatcher::Declarative -base, -default => {
    token_delimiter => '/',
};

on qr{^/$} => sub {
    my %args = @_;
    my $tt = delete $args{tt};;
    my $connections = delete $args{connections};

    my $data;
    $tt->process('users.tt', {connections => $connections}, \$data);

    return $data;
};

on ['tv', /\w+/] => sub {
    "O HAI";
};

1;
