package MojoX::Scaffold::Model::ObjectDB;

use strict;
use warnings;

use base 'MojoX::Scaffold::Model';

__PACKAGE__->attr('resource');


sub class_data {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('class_data',$self->resource);
}

sub index {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('index',$self->resource);
}

sub show {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('show',$self->resource);
}

sub new_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('new_form',$self->resource);
}

sub edit_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('edit_form',$self->resource);
}

sub delete_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('edit_form',$self->resource);
}

sub create {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('create',$self->resource);
}

sub update {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('update',$self->resource);
}

sub delete {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('delete',$self->resource);
}

sub source {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('source',$self->resource);
}

sub base_class {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('base_class',$self->resource);
}

sub loop {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('loop', $self->resource);
}

sub number_of_rows {
    my $self = shift;
    my $items_name = $self->resource->{model}->{items_name};
    return qq|\$${items_name}->number_of_rows|;
}

sub item_accessor {
    my $self = shift;
    my $item_name = $self->resource->{model}->{item_name};
    return sub {
        my $key  = shift;
        return qq|\$$item_name->column('$key')|;
    }
}

sub default_base_class {
    my $self = shift;
    return $self->{resource}->{app}->{name}.'::ObjectDB';
}

sub default_namespace {
    my $self = shift;
    return $self->{resource}->{app}->{name}.'::ObjectDB';
}

sub instance_accessor {
    my $self = shift;
    return 'objectdb';
}


1;

__DATA__

%%############################################################################
@@ class_data
%% my $resource = shift;


%%############################################################################
@@ index
%% my $resource = shift;
    my $self = shift;

    my $<%%= $resource->{last_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->find;

    $self->stash(<%%= $resource->{model}->{items_name} %%> => $<%%= $resource->{last_name} %%>);

%%############################################################################
@@ show
%% my $resource = shift;
    my $self = shift;

    my $id = $self->stash('id');

    my $<%%= $resource->{model}->{item_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->find(id=>$id);

    $self->stash(<%%= $resource->{model}->{item_name} %%> => $<%%= $resource->{model}->{item_name} %%>);

%%############################################################################
@@ new_form
%% my $resource = shift;
    my $self = shift;

%%############################################################################
@@ edit_form
%% my $resource = shift;
    my $self = shift;

    my $id = $self->stash('id');

    my $<%%= $resource->{model}->{item_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->find(id=>$id);

    $self->stash(<%%= $resource->{model}->{item_name} %%> => $<%%= $resource->{model}->{item_name} %%>);

%%############################################################################
@@ delete_form
%% my $resource = shift;
    my $self = shift;

%%############################################################################
@@ create
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
    my $self = shift;

    my @form_fields = (<%%=$form_fields_list%%>);
    my %data;
    for my $field_name (@form_fields) {
        $data{$field_name} = $self->req->param($field_name);
    }

    my $<%%= $resource->{model}->{item_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->create(%data);

    my $id = $<%%= $resource->{model}->{item_name} %%>->column('id');

%%############################################################################
@@ update
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
    my $self = shift;

    my $id = $self->stash('id');

    my %data;
    $data{id} = $id;

    my @form_fields = (<%%=$form_fields_list%%>);
    for my $field_name (@form_fields) {
        $data{$field_name} = $self->req->param($field_name);
    }

    my $<%%= $resource->{model}->{item_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->update(%data);


%%############################################################################
@@ delete
%% my $resource = shift;
    my $self = shift;

    my $id = $self->stash('id');

    my $<%%= $resource->{model}->{item_name} %%> = $self->objectdb('<%%= $resource->{model}->{class_last} %%>')->delete(where => [id => $id]);

    $self->flash(message => 'Your data has been deleted successfully!');


%%############################################################################
@@ source
%% my $resource = shift;
package <%%= $resource->{model}->{class} %%>;

use strict;
use warnings;

use base '<%%= $resource->{model}->{base_class} %%>';

__PACKAGE__->schema;

1;

%%############################################################################
@@ base_class
%% my $resource = shift;
package <%%= $resource->{model}->{base_class} %%>;

use strict;
use warnings;

use base 'ObjectDB';

use ObjectDB::Connector;

my $db_system = ''; ## mysql or sqlite
my $db_name   = ''; ## mysql: name of database, sqlite: name of file
my $db_user   = '';
my $db_pass   = '';


sub init_conn {
    my $self = shift;
    return ObjectDB::Connector->new("dbi:$db_system:$db_name", $db_user, $db_pass) 
}

sub namespace { return '<%%= $resource->{model}->{namespace} %%>'; }

sub rows_as_object { 1; }


1;

%%############################################################################
@@ loop
%% my $resource = shift;
while (my $<%%= $resource->{model}->{item_name} %%> = $<%%= $resource->{model}->{items_name} %%>->next) {



__END__
