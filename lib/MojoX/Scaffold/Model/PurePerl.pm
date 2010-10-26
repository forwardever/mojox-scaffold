package MojoX::Scaffold::Model::PurePerl;

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

sub create_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('create_form',$self->resource);
}

sub update_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('update_form',$self->resource);
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

1;

__DATA__

%%############################################################################
@@ class_data
%% my $resource = shift;
# can be deleted after you have implemented your database
my @<%%= $resource->{last_name} %%>;
my $counter = 0;


%%############################################################################
@@ index
%% my $resource = shift;
    my $self = shift;
    # Read all resource items from a database
    # to make them available in the template index.html.ep
    # Save each row from the DB into a hash (column name is hash key, column value is hash value)
    # and push the hash reference into an array
    
    $self->stash(<%%= $resource->{last_name} %%> => \@<%%= $resource->{last_name} %%> );

%%############################################################################
@@ show
%% my $resource = shift;
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $resource->{last_name} %%>[$id-1];

    # and save it to the stash to make it available in the template show.html.ep
    $self->stash(item => $item);

%%############################################################################
@@ create_form
%% my $resource = shift;
    my $self = shift;

%%############################################################################
@@ update_form
%% my $resource = shift;
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $resource->{last_name} %%>[$id-1];

    # and save it to the stash to make it available in the template update_form.html.ep
    $self->stash(item => $item);

%%############################################################################
@@ create
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
    my $self = shift;

    # Increase counter, using a real database, you would have to
    # retrieve the generated auto increment value for example
    $counter++;

    # List of all field names
    my @form_fields = (<%%=$form_fields_list%%>);


    # save passed form data in array (key value pairs)
    my %data;
    $data{'id'} = $counter;
    for my $field_name (@form_fields) {
        $data{$field_name} = $self->req->param($field_name);
    }

    # save row to <%%= $resource->{last_name} %%> hash
    push @<%%= $resource->{last_name} %%>, {%data};

%%############################################################################
@@ update
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $resource->{last_name} %%>[$id-1];

    # List of all field names
    my @form_fields = (<%%=$form_fields_list%%>);

    # save passed form data in hash
    for my $field_name (@form_fields) {
        $item->{$field_name} = $self->req->param($field_name);
    }

%%############################################################################
@@ delete
%% my $resource = shift;
    my $self = shift;
    # TO DO

__END__
