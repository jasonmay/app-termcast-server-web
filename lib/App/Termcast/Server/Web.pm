package App::Termcast::Server::Web;
use Moose;
use Bread::Board;

use Template;

extends 'Bread::Board::Container';

has '+name' => ( default => sub { (shift)->meta->name } );

has tc_socket => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has port => (
    is => 'ro',
    isa => 'Int',
    default => 5000,
);

has tt_root => (
    is => 'ro',
    isa => 'Str',
    default => 'web/tt',
);

sub BUILD {
    my $self = shift;
    container $self => as {
        service plack_app => (
            block => sub {
                my $service = shift;
                my $app_class = 'App::Termcast::Server::Web::App';
                Class::MOP::load_class($app_class);

                return $app_class->new( %{$service->params} );
            },
            lifecycle    => 'Singleton',
            dependencies => ['hippie', 'tt', 'tc_socket', 'connections'],
        );

        service tc_socket => $self->tc_socket;

        service hippie => (
            class => 'App::Termcast::Server::Web::Hippie',
            lifecycle => 'Singleton',
        );

        service connections    => (
            class      => 'App::Termcast::Server::Web::Connections',
            lifecycle => 'Singleton',
            dependencies => ['hippie', 'tc_socket'],
        );

        service tt => Template->new(INCLUDE_PATH => $self->tt_root);
    };
}

sub final_app {
    my $self = shift;
    $self->resolve(service => 'connections')->vivify_connection;
    return $self->resolve(service => 'plack_app')->to_app();
}

sub run {
    my $self = shift;

    my $app = $self->final_app;

    require Plack::Loader;
    Plack::Loader->auto(port => $self->port)->run($app);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
