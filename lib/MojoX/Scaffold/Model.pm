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

sub create_form {
    die 'no create_form method defined';
}

sub update_form {
    die 'no update_form method defined';
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

sub change_tags {
    my $self = shift;

    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');
}

1;
