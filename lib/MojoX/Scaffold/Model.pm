package MojoX::Scaffold::Model;

use strict;
use warnings;

use base 'Mojo::Command';

sub class_data {
}


sub index {
    die 'no index method defined';
}

sub show {
    die 'no show method defined';
}

sub new_form {
    die 'no new_form method defined';
}

sub edit_form {
    die 'no edit_form method defined';
}

sub create {
    die 'no create method defined';
}

sub update {
    die 'no update method defined';
}

sub delete {
    die 'no delete method defined';
}

sub source {
}

sub change_tags {
    my $self = shift;

    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');
}

1;
