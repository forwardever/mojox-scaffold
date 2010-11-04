package Mojolicious::Plugin::ModelInstance;

use strict;
use warnings;

use base 'Mojolicious::Plugin';
use Mojo::ByteStream;

sub register {
    my ($self, $app, $options) = @_;

    my $namespace = $options->{namespace};
    my $method    = $options->{method};


    $app->helper(
        $method => sub {
            my $c          = shift;
            my $class_name = shift;

            my $class = $namespace."::$class_name";

            Mojo::Loader->new->load($class);

            return $class->new;

        }
    );
}

1;
