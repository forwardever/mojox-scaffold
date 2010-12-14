package Test2::Users;

use strict;
use warnings;

use base 'Mojolicious::Controller';


sub index {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->stash(route_name => $route_name);
}


sub show {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->stash(route_name => $route_name);
}


sub new_form {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->stash(route_name => $route_name);
}


sub edit_form {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->stash(route_name => $route_name);
}

sub delete_form {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->stash(route_name => $route_name);
}


sub create {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->render_text('POST request, create method executed! Route name: '.$route_name); # can be deleted
}


sub update {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->render_text('PUT request, update method executed! Route name: '.$route_name); # can be deleted
}


sub delete {
    my $self = shift;
    my $route_name = $self->match->endpoint->name;
    $self->render_text('DELETE request, delete method executed! Route name: '.$route_name); # can be deleted
}

1;
