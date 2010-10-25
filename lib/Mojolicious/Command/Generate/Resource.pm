package Mojolicious::Command::Generate::Resource;

use strict;
use warnings;

use base 'Mojo::Command';

use Mojo::ByteStream;
use Mojo::Server;


__PACKAGE__->attr(description => <<'EOF');
Generate a resource
EOF
__PACKAGE__->attr(usage => <<"EOF");
usage: $0 generate resource [APP_NAME RESOURCE_NAME FIELD_NAME:TYPE -OPTION:VALUE]
EOF


### mojolicious generate resource MyApp resource_name
sub run {
    my $self     = shift;
    my $res_name = shift || die 'no resource name passed';
    my @params = @_;

    # Create resource hash ref
    my $resource = {};

    # Save resource name
    $resource->{name} = $res_name;

    # Get paths
    $self->get_paths($resource);

    # Validate paths
    $self->validate_paths($resource);

    # Validate parameters
    $self->validate_params([@params], $resource);

    # Unique id and form fields
    $self->process_fields($resource);


    # Config path
    # my $conf_path = 'config/resources/'.$res_name.'.conf';
    # Save config file for further use by ORMs
    # $self->render_to_rel_file('config', $conf_path, $config);


    # Change tags
    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');


    # Create a controller file
    $self->render_to_rel_file('controller', $resource->{paths}->{ctrl}, $resource);


    # Create a test file
    $self->render_to_rel_file('test', $resource->{paths}->{test}, $resource);


    # Create template files
    my $tmpl_path = $resource->{paths}->{tmpl};
    my $layout_path = $resource->{paths}->{layout};

    $self->render_to_rel_file('layout',      $layout_path.'/resources.html.ep');
    $self->render_to_rel_file('index',       $tmpl_path.'/index.html.ep', $resource);
    $self->render_to_rel_file('show',        $tmpl_path.'/show.html.ep', $resource);
    $self->render_to_rel_file('create_form', $tmpl_path.'/create_form.html.ep', $resource);
    $self->render_to_rel_file('update_form', $tmpl_path.'/update_form.html.ep', $resource);


    # Info
    print qq|Make sure that the following command can be found in the |.
          qq|startup method of your routing file:\n|.
          qq|    \$self->plugin('resourceful_routes');\n|.
          qq|    \$self->resources('$resource->{name}');|;

}


sub process_fields {
    my $self     = shift;
    my $resource = shift;

    my $options     = $resource->{options};
    my $data_fields = $resource->{data_fields};

    # Look for unique key
    my $unique_key = $options->{unique_key};

    # No unique key passed
    $unique_key = 'id' unless defined $unique_key;

    # Form fields
    my @form_fields;
    my @form_field_names;
    my $unique_key_type;
    foreach my $field (@$data_fields){
        if ($field->{name} eq $unique_key) {
            $unique_key_type = $field->{type};
        }
        else {
            push @form_fields, $field;
            push @form_field_names, $field->{name};
        }
    }

    # No unique key type passed
    $unique_key_type = 'int' unless defined $unique_key_type;

    $resource->{unique_key}       = $unique_key;
    $resource->{unique_key_type}  = $unique_key_type;
    $resource->{form_fields}      = [@form_fields];
    $resource->{form_field_names} = [@form_field_names];
}


sub validate_params {
    my $self     = shift;
    my $params   = shift;
    my $resource = shift;

    my $valid_options = {
        'unique_key' => 1,
    };

    my $valid_data_types = {
        'int'    => 1,
        'string' => 1,
        'text'   => 1,
    };

    my %options;
    my @data_fields;

    foreach my $param (@$params){
        # Cleanup
        chomp $param;

        # Validate general format
        if ($param !~m/^-{0,1}[\w]+:[\w]+$/){
            die qq|format of parameters has to be: "name:type" or | .
                qq|"-option_name:value", no spaces, just alphanumeric, | .
                qq|"_" (underscore) and "-" (hyphen, ahead of options), | .
                qq|malformed parameter >> "$param"|;
        }

        # Split data
        my ($name, $type) = split(/:/, $param );

        # Is option
        my $option = 0;
        if ($name =~s/^-//){
            $option = 1;
        }

        # Validate options
        if ($option && !$valid_options->{$name}){
            die qq|unknown option "$name", available options: |.
                join(', ', map {'"'.$_.'"'} keys %$valid_options).
                qq|, malformed parameter >> "$param"|;
        }

        # Validate form field
        elsif (!$valid_data_types->{$type}){
            die qq|wrong format "$type", format can be: |.
                join(', ', map {'"'.$_.'"'} keys %$valid_data_types).
                qq|, malformed parameter >> "$param"|;
        }

        # Save options
        if ($option) {
            $options{$name} = $type;
        }
        # Save data fields
        else {
            push @data_fields, {name => $name, type => $type};
        }
    }

    # Save to resource
    $resource->{options}       = {%options};
    $resource->{data_fields}   = [@data_fields];

}


sub get_paths {
    my $self     = shift;
    my $resource = shift;

    # Resource name
    my $resource_name = $resource->{name};

    # Get app instance
    my $app       = Mojo::Server->new->app || die 'app not found';
    my $namespace = $app->routes->namespace;

    # app name
    my @namespace = split(/::/, $namespace);
    my $app_name = $namespace[0];

    # Controller/Ressource class
    my $resource_class = $namespace.'::'.Mojo::ByteStream->new($resource_name)
      ->camelize->to_string;

    # Controller path
    my $ctrl_path = 'lib/'.$self->class_to_path($resource_class);

    # Template base path
    my $tmpl_base = $app->renderer->root;

    # Template path
    my $tmpl_sub_path = join('/', split(/-/, $resource_name) );
    my $tmpl_path = $tmpl_base.'/'.$tmpl_sub_path;

    # Layout path
    my $layout_path = $tmpl_base.'/layouts';

    # Test path
    my $test_path = '/t/'.join('/', split(/-/, $resource_name) ).'/standard.t';

    # Dispatch path
    my $dispatch_path = '/'.join('/', split(/-/, $resource_name) );

    # Resource last name
    my @resource_name_parts = split(/-/, $resource_name);
    my $last_name           = $resource_name_parts[-1];

    # Save paths to resource hash ref
    $resource->{paths} = {
        ctrl      => $ctrl_path,
        tmpl      => $tmpl_path,
        layout    => $layout_path,
        test      => $test_path,
        tmpl_base => $tmpl_base,
    };

    # Save app name to resource hash ref
    $resource->{app} = {
        name => $app_name,
    };

    # Save resource class
    $resource->{class}         = $resource_class;
    $resource->{dispatch_path} = $dispatch_path;
    $resource->{last_name}     = $last_name;

}


sub validate_paths {
    my $self     = shift;
    my $resource = shift;

    my $tmpl_base = $resource->{paths}->{tmpl_base};
    my $tmpl_path = $resource->{paths}->{tmpl};
    my $ctrl_path = $resource->{paths}->{ctrl};

    # Make sure template path exists
    unless ( -e $tmpl_base ){
        die qq|Template path "$tmpl_base" not found! Make sure that you |.
            qq|switch to the directory where your application is located |.
            qq|before running "script/myapp generate resource"!|;
    }

    # Make sure template path does not already exists
    if ( -e $tmpl_path ){
        die qq|Template path "$tmpl_path" already exists. Resource could |.
            qq|NOT be created!|;
    }

    # Make sure controller file does not already exists
    if ( -e $ctrl_path ){
        die qq|Controller file $ctrl_path already exists. Resource could |.
            qq|NOT be created!|;
    }
}

1;


__DATA__

%%############################################################################
@@ index
%% my $resource       = shift;
%% my $res_name       = $resource->{name};
%% my $form_fields    = $resource->{form_fields};
%% my $res_last_name  = $resource->{last_name};

% layout 'resources', title => 'Index';
    <h1>List <%%= $res_name %%></h1><br />

    <table>
      <tr>
        %% foreach my $form_field (@$form_fields) {
        <th><%%= $form_field->{name} %%></th>
        %% }
        <th>Edit</th>
        <th>View</th>
      </tr>
      % foreach my $item (@$<%%= $res_last_name %%>){
      <tr>
        %% foreach my $form_field (@$form_fields) {
        <td><%= $item->{<%%= $form_field->{name} %%>} %></td>
        %% }
        <td>
          <%= link_to 'Edit' => '<%%= $res_name %%>_update_form', { id => $item->{id} } %>
        </td>
        <td>
          <%= link_to 'View' => '<%%= $res_name %%>_show', { id => $item->{id} } %>
        </td>
      </tr>
      % }
      % if (!$<%%= $res_last_name %%> || !@$<%%= $res_last_name %%>) {
      <tr>
        <td colspan="<%%= @$form_fields+2 %%>">No Results</td>
      </tr>
      % }
    </table>

    <br />
    <%= link_to 'Index' => '<%%= $res_name %%>_index' %>
    <%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>


%%############################################################################
@@ show
%% my $resource    = shift;
%% my $res_name    = $resource->{name};
%% my $form_fields = $resource->{form_fields};
% layout 'resources', title => 'Show';
<h1>Show one item of <%%= $res_name %%></h1><br />

<table>
    %% foreach my $form_field (@$form_fields) {
    <tr>
        <td>
            <%%=$form_field->{name}%%>
        </td>
        <td>
            <%= $item->{<%%=$form_field->{name}%%>} %>
        </td>
    </tr>

    %% }
</table>

<br />
<%= link_to 'Index' => '<%%= $res_name %%>_index' %>
<%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>
<%= link_to 'Edit'  => '<%%= $res_name %%>_update_form', { id => $item->{id} } %>


%%############################################################################
@@ create_form
%% my $resource    = shift;
%% my $res_name    = $resource->{name};
%% my $form_fields = $resource->{form_fields};
% layout 'resources', title => 'Create Form';

<h1>Create a new item of <%%= $res_name %%></h1><br />
<%= form_for '<%%= $res_name %%>_create', method => 'post' => begin %>
  %% foreach my $field (@$form_fields) {
  %% if ($field->{type} eq 'string' || $field->{type} eq 'int') {
    <%%= $field->{name} %%>:<br />
    <%= text_field '<%%= $field->{name} %%>', value => '' %><br /><br />
  %% }
  %% elsif ($field->{type} eq 'text') {
    <%%= $field->{name} %%>:<br />
    <%= text_area <%%= $field->{name} %%> => begin %><% end %><br /><br />
  %% }
  %% }
    <%= submit_button 'Create' %>
<% end %>

<br />
<%= link_to 'Index' => '<%%= $res_name %%>_index' %>
<%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>


%%############################################################################
@@ update_form
%% my $resource    = shift;
%% my $res_name    = $resource->{name};
%% my $form_fields = $resource->{form_fields};
% layout 'resources', title => 'Update Form';

<h1>Edit one item of <%%= $res_name %%></h1><br />

<%= form_for '<%%= $res_name %%>_update', {id => $id}, method => 'post' => begin %>
  %% foreach my $field (@$form_fields) {
  %% if ($field->{type} eq 'string' || $field->{type} eq 'int') {
    <%%= $field->{name} %%>:<br />
    <%= text_field '<%%= $field->{name} %%>', value => $item->{<%%= $field->{name} %%>} %><br /><br />
  %% }
  %% elsif ($field->{type} eq 'text') {
    <%%= $field->{name} %%>:<br />
    <%= text_area <%%= $field->{name} %%> => begin %><%=$item->{<%%= $field->{name} %%>}%><% end %><br /><br />
  %% }
  %% }
    <%= hidden_field '_method' => 'put' %><br />
    <%= submit_button 'Update' %>
<% end %>

<br />
<%= link_to 'Index' => '<%%= $res_name %%>_index' %>
<%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>


%%############################################################################
@@ layout
<!doctype html>
  <html>
    <head>
      <title>
        <%= $title %>
      </title>
      <style type="text/css">
        body, p, th, td {
          font-family: arial, verdana, helvetica, sans-serif;
          font-size:   14px;
        }
        table {
          border-collapse: collapse;
          border-color: #C0C0C0;
          border-width: 0 0 1px 1px;
          border-style: solid;
        }
        th, td {
          border-collapse: collapse;
          border-color: #C0C0C0;
          border-width: 1px 1px 0 0;
          border-style: solid;
          padding:4px;
        }
      </style>
    </head>
  <body><%= content %></body>
</html>


%%############################################################################
@@ controller
%% my $resource         = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
%% my $res_last_name    = $resource->{last_name};
package <%%= $resource->{class} %%>;

use strict;
use warnings;

use base 'Mojolicious::Controller';

# can be deleted after you have implemented your database
my @<%%= $res_last_name %%>;
my $counter = 0;


sub index {
    my $self = shift;
    # Read all resource items from a database
    # to make them available in the template index.html.ep
    # Save each row from the DB into a hash (column name is hash key, column value is hash value)
    # and push the hash reference into an array

    $self->stash(<%%= $res_last_name %%> => \@<%%= $res_last_name %%> );

}


sub show {
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $res_last_name %%>[$id-1];

    # and save it to the stash to make it available in the template show.html.ep
    $self->stash(item => $item);

}


sub create_form {
    my $self = shift;
}


sub update_form {
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $res_last_name %%>[$id-1];

    # and save it to the stash to make it available in the template update_form.html.ep
    $self->stash(item => $item);

}


sub create {
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

    # save row to <%%= $res_last_name %%> hash
    push @<%%= $res_last_name %%>, {%data};


    # and redirect to "show" in order to display the created resource
    $self->redirect_to('<%%= $resource->{name} %%>_show', id => $counter );

}


sub update {
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $res_last_name %%>[$id-1];

    # List of all field names
    my @form_fields = (<%%=$form_fields_list%%>);

    # save passed form data in hash
    for my $field_name (@form_fields) {
        $item->{$field_name} = $self->req->param($field_name);
    }

    # redirect to "show" in order to display the updated resource
    $self->redirect_to('<%%= $resource->{name} %%>_show', id => $id );

}


sub delete {
    my $self = shift;
    # TO DO
}

1;


%%############################################################################
@@ test
%% my $resource = shift;
%% my @form_fields   = @{$resource->{form_fields}};
%% my $dispatch_path = $resource->{dispatch_path};
%% my $test_num = 16 + @form_fields * 5;
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

plan tests => <%%= $test_num %%>;

my $t = Test::Mojo->new(app => '<%%= $resource->{app}->{name} %%>');


################
# Prepare data

# Define field names and sample data (hash ref)
my $fields = {
%% foreach my $field (@form_fields) {
    %% my $value = $field->{type} eq 'text' || $field->{type} eq 'string' ? $field->{name}.'_value' : 1;
    <%%= $field->{name} %%> => '<%%= $value %%>',
%% }
};


# For updates, we modify field values a bit (append "_edit" or add 1)
my $fields_put = {};
while (my ($key, $value) = each (%$fields)) {
    if ($value eq 1){
        $fields_put->{$key} = $value+1;
    }
    else {
        $fields_put->{$key} = $value.'_edit';
    }
}
# ... and add a method field to allow Mojolicious to transform our post
# request to a put request
$fields_put->{_method} = 'put';


################
### GET request dispatched to CREATE_FORM method
$t->get_ok('<%%= $dispatch_path %%>/new')
  ->status_is(200);

# look for form fields
foreach my $key (keys %$fields) {
    my $search_key = quotemeta( qq|name="$key"| );
    $t->content_like(qr/$search_key/s);
}


################
### POST request to create a new entry
$t->post_form_ok('<%%= $dispatch_path %%>', $fields)
  ->status_is(302) # 302 redirect
  ->header_like('location' => qr|<%%= $dispatch_path %%>/1|);


################
### GET request dispatched to SHOW method
$t->get_ok('<%%= $dispatch_path %%>/1')
  ->status_is(200);

# look for field_name + any number of characters (incl. line breaks) + field_value
while (my ($key, $value) = each (%$fields) ) {
    my $search_key   = quotemeta($key);
    my $search_value = quotemeta($value);
    $t->content_like(qr/$search_key.*$search_value/s);
}


################
### GET request dispatched to INDEX method
$t->get_ok('<%%= $dispatch_path %%>')
  ->status_is(200);

# look for field_name + any number of characters (incl. line breaks) + field_value
while (my ($key, $value) = each (%$fields) ) {
    my $search_key   = quotemeta($key);
    my $search_value = quotemeta($value);
    $t->content_like(qr/$search_key.*$search_value/s);
}


################
### GET request dispatched to UPDATE_FORM method
$t->get_ok('<%%= $dispatch_path %%>/1/edit')
  ->status_is(200);

# look for form field names and values
while (my ($key, $value) = each (%$fields) ) {
    my $search_key   = quotemeta( qq|name="$key"| );
    my $search_value = quotemeta( $value );
    $t->content_like(qr/$search_key.*$search_value/s);
}


################
### POST/PUT request dispatched to UPDATE method

$t->post_form_ok('<%%= $dispatch_path %%>/1', $fields_put)
  ->status_is(302)
  ->header_like('location' => qr|<%%= $dispatch_path %%>/1|);


################
### GET request dispatched to SHOW method
$t->get_ok('<%%= $dispatch_path %%>/1')
  ->status_is(200);

# look for field_name + any number of characters (incl. line breaks) + field_value
while (my ($key, $value) = each (%$fields_put) ) {
    next if $key eq '_method';
    my $search_key   = quotemeta($key);
    my $search_value = quotemeta($value);
    $t->content_like(qr/$search_key.*$search_value/s);
}


1;


%%############################################################################
@@ config
% my $config = shift;
%= $config

__END__
