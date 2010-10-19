package Test;

use strict;
use warnings;

use base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Only log errors to STDERR
    $self->log->level('fatal');

    $self->plugin('resourceful_routes');
    $self->resources('users','admin-users');

}

1;
