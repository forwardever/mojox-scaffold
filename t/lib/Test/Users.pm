package Test::Users;

use strict;
use warnings;

use base 'Mojolicious::Controller';


sub index {
    my $self = shift;
    # Read all resource items from a database and save them in the stash
    # to make them available in the template index.html.ep
}


sub show {
    my $self = shift;
    # Read existing data from a database using
    # $self->stash('id')
    # and save it to the stash to make it available in the template
    # show.html.ep
}


sub create_form {
    my $self = shift;
}


sub update_form {
    my $self = shift;
    # Read existing data for the resource item from a database using
    # $self->stash('id')
    # and save it to the stash to
    # make it available in the template update_form.html.ep
}


sub create {
    my $self = shift;
    # fetch the newly created id
    # $id = ...;
    # and redirect to "show" in order to display the created resource
    # $self->redirect_to('users_show', id => $id );
    $self->render_text('POST request, create method executed!'); # can be deleted
}


sub update {
    my $self = shift;
    # redirect to "show" in order to display the updated resource
    # $self->redirect_to('users_show', id => $self->stash('id') );
    $self->render_text('PUT request, update method executed!'); # can be deleted
}


sub delete {
    my $self = shift;
    $self->render_text('DELETE request, delete method executed!'); # can be deleted
}

1;
