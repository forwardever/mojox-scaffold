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

sub create_form {
    die 'no create_form method defined';
}

sub update_form {
    die 'no update_form method defined';
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
