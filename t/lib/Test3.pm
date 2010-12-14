package Test3;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('resourceful_routes');
    $self->resources('users', -only => ['delete', 'delete_form']);

}

1;
