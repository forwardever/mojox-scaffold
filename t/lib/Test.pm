package Test;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->plugin('resourceful_routes');
    $self->resources('users', 'admin-users', 'member' => -singular => 1);

}

1;
