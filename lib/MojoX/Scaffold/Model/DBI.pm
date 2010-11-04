package MojoX::Scaffold::Model::DBI;

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
    return qq|\@\$${items_name}|;
}

sub item_accessor {
    my $self = shift;
    my $item_name = $self->resource->{model}->{item_name};
    return sub {
        my $key  = shift;
        return qq|\$${item_name}->{'$key'}|;
    }
}

sub default_base_class {
    my $self = shift;
    return $self->{resource}->{app}->{name}.'::DBI';
}

sub default_namespace {
    my $self = shift;
    return $self->{resource}->{app}->{name}.'::DBI';
}

sub instance_accessor {
    my $self = shift;
    return 'dbh';
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

    my $sth = $self->dbh('<%%= $resource->{model}->{class_last} %%>')->prepare("select * from <%%= $resource->{model}->{items_name} %%>");
    $sth->execute;
    my $<%%= $resource->{model}->{items_name} %%> = $sth->fetchall_arrayref( {} );

    $self->stash(<%%= $resource->{model}->{items_name} %%> => $<%%= $resource->{model}->{items_name} %%>);

%%############################################################################
@@ show
%% my $resource = shift;
    my $self = shift;

    my $id = $self->stash('id');

    my $sth = $self->dbh('<%%= $resource->{model}->{class_last} %%>')->prepare("select * from <%%= $resource->{model}->{items_name} %%> where id=?");
    $sth->execute($id);
    my $<%%= $resource->{model}->{item_name} %%> = $sth->fetchrow_hashref;

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

    my $sth = $self->dbh('<%%= $resource->{model}->{class_last} %%>')->prepare("select * from <%%= $resource->{model}->{items_name} %%> where id=?");
    $sth->execute($id);
    my $<%%= $resource->{model}->{item_name} %%> = $sth->fetchrow_hashref;


    $self->stash(<%%= $resource->{model}->{item_name} %%> => $<%%= $resource->{model}->{item_name} %%>);

%%############################################################################
@@ create
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
%% my $placeholders = join (',', map { '?' } @{$resource->{form_field_names}});
    my $self = shift;

    my @form_fields = (<%%=$form_fields_list%%>);
    my @columns;
    my @values;

    for my $field (@form_fields) {
        my $value = $self->req->param($field);
        push @values, $value;
        push @columns, "`$field`";
    }
    my $columns = join(',', @columns);

    my $dbh = $self->dbh('<%%= $resource->{model}->{class_last} %%>');
    my $sth = $dbh->prepare(qq|insert into <%%= $resource->{model}->{items_name} %%> ($columns) values (<%%= $placeholders %%>)|);
    $sth->execute(@values);

    my $id = $dbh->last_insert_id(undef,undef,undef,undef);

%%############################################################################
@@ update
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
%% my $placeholders = join (',', map { '?' } @{$resource->{form_field_names}});
    my $self = shift;

    my $id = $self->stash('id');

    my @form_fields = (<%%=$form_fields_list%%>);
    my @columns;
    my @values;

    for my $field (@form_fields) {
        my $value = $self->req->param($field);
        push @values, $value;
        push @columns, "$field = ?";
    }
    my $columns = join(',', @columns);

    my $sth = $self->dbh('<%%= $resource->{model}->{class_last} %%>')->prepare(qq|update <%%= $resource->{model}->{items_name} %%> set $columns where id = ?|);
    $sth->execute(@values, $id);

%%############################################################################
@@ delete
%% my $resource = shift;
    my $self = shift;
    # TO DO

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

use base 'DBI';

my $db_system = ''; ## mysql or sqlite
my $db_name   = ''; ## mysql: name of database, sqlite: name of file
my $db_user   = '';
my $db_pass   = '';

sub new {
    my $dbh = DBI->connect("dbi:$db_system:$db_name:", $db_user, $db_pass)
      or die $DBI::errstr;
    return $dbh;
}


1;

%%############################################################################
@@ loop
%% my $resource = shift;
foreach my $<%%= $resource->{model}->{item_name} %%> (@$<%%= $resource->{model}->{items_name} %%>) {

__END__
