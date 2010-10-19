package Test::Users;

use strict;
use warnings;

use base 'Mojolicious::Controller';


sub index {
    my $self = shift;
}


sub show {
    my $self = shift;
}


sub create_form {
    my $self = shift;
}


sub update_form {
    my $self = shift;
}


sub create {
    my $self = shift;
    $self->render_text('POST request, create method executed!'); # can be deleted
}


sub update {
    my $self = shift;
    $self->render_text('PUT request, update method executed!'); # can be deleted
}


sub delete {
    my $self = shift;
    $self->render_text('DELETE request, delete method executed!'); # can be deleted
}

1;
