package Test2;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('resourceful_routes');
    $self->resources(
        'users', -except => ['delete', 'delete_form'],
        'member', -singular => 1, -except => ['delete', 'delete_form']
    );

}

1;
