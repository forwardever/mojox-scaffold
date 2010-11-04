package MojoX::Scaffold::Template;

use strict;
use warnings;

use base 'Mojo::Command';

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
    die 'no update_form method defined';
}

sub delete_form {
    die 'no delete_form method defined';
}

sub layout {
    die 'no layout method defined';
}

sub change_tags {
    my $self = shift;

    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');
}

1;
