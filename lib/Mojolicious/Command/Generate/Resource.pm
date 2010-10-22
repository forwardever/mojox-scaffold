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


    # Config path
    #my $conf_path = 'config/resources/'.$res_name.'.conf';

    # Read data fields
    my $config;
    my @form_fields;
    my %form_fields_type;
    my $unique_key;
    my $unique_key_type;


    # Validate parameters
    $self->validate_params([@params]);


    foreach my $param (@params){

        my ($name, $type) = split(/:/, $param );

        # Options
        if ($param =~m/^-/){
            if ( $name eq '-unique_key' ){
                $unique_key = $type;
            }
        }
        # Data fields
        else {
            push @form_fields, $name;
            $form_fields_type{$name} = $type;
            #$config .= $param."\n";
        }
    }


    # no unique key passed
    if (!$unique_key){
        # id form field
        if ($form_fields_type{id}){
            my @new_form_fields = grep { $_ ne 'id' } @form_fields;
            @form_fields = @new_form_fields;
            $unique_key = 'id';
            $unique_key_type = $form_fields_type{id};
            $form_fields_type{id} = undef;
        }
        else {
            $unique_key = 'id';
            $unique_key_type = 'int';
        }
    }

    # Save config file for further use by ORMs
    # $self->render_to_rel_file('config', $conf_path, $config);


    # Change tags
    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');


    # Create a controller file
    $self->render_to_rel_file('controller', $resource->{paths}->{ctrl}, $resource, \@form_fields);

    # Create template files
    $self->render_to_rel_file('resourceful_layout', $resource->{paths}->{layout}."/resourceful_layout.html.ep", $res_name);
    $self->render_to_rel_file('index',       $resource->{paths}->{tmpl}."/index.html.ep", $res_name, \@form_fields);
    $self->render_to_rel_file('show',        $resource->{paths}->{tmpl}."/show.html.ep", $res_name, \@form_fields);
    $self->render_to_rel_file('create_form', $resource->{paths}->{tmpl}."/create_form.html.ep", $res_name, \@form_fields, \%form_fields_type);
    $self->render_to_rel_file('update_form', $resource->{paths}->{tmpl}."/update_form.html.ep", $res_name, \@form_fields, \%form_fields_type);

}


sub validate_params {
    my $self   = shift;
    my $params = shift;

    my $valid_options = {
        'unique_key' => 1,
    };

    my $valid_data_types = {
        'int'    => 1,
        'string' => 1,
        'text'   => 1,
    };

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

        # Validate options
        if ($name =~s/^-// && !$valid_options->{$name}){
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
    }
}


sub get_paths {
    my $self     = shift;
    my $resource = shift;

    # Resource name
    my $resource_name = $resource->{name};

    # Get app instance and name
    my $app      = Mojo::Server->new->app || die 'app not found';
    my $app_name = $app->routes->namespace;

    # Controller base path
    my $ctrl_base = 'lib/'.$app_name;

    # Controller/Ressource class
    my $resource_class = $app_name.'::'.Mojo::ByteStream->new($resource_name)
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

    # Save paths to resource hash ref
    $resource->{paths} = {
        ctrl      => $ctrl_path,
        tmpl      => $tmpl_path,
        layout    => $layout_path,
        ctrl_base => $ctrl_base,
        tmpl_base => $tmpl_base
    };

    # Save app name to resource hash ref
    $resource->{app} = {
        name => $app_name,
    };

    # Save resource class
    $resource->{class} = $resource_class;

}


sub validate_paths {
    my $self     = shift;
    my $resource = shift;

    my $tmpl_base = $resource->{paths}->{tmpl_base};
    my $ctrl_base = $resource->{paths}->{ctrl_base};
    my $tmpl_path = $resource->{paths}->{tmpl};
    my $ctrl_path = $resource->{paths}->{ctrl};

    # Make sure template path exists
    unless ( -e $tmpl_base ){
        die qq|Template path "$tmpl_base" not found! Make sure that you |.
            qq|switch to the directory where your application is located |.
            qq|before running "script/myapp generate resource"!|;
    }

    # Make sure controller path exists
    unless ( -e $ctrl_base ){
        die qq|Controller path "$ctrl_base" not found! Make sure that |.
            qq|you switch to the directory where your application is |.
            qq|located before running "script/myapp generate resource"!|;
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
%% my $res_name       = shift;
%% my $form_fields    = shift;
%% my @res_name_parts = split(/-/,$res_name);
%% my $res_name_last  = $res_name_parts[-1];

% layout 'resourceful_layout', title => 'Index';
<h1>List <%%= $res_name %%></h2><br />

<table>
    <tr>
        %% foreach my $form_field (@$form_fields) {
        <th>
          <%%= $form_field %%>
        </th>
        %% }
        <th>
          Edit
        </th>
        <th>
          View
        </th>
    </tr>
    % foreach my $item (@$<%%= $res_name_last %%>){
    <tr>
        %% foreach my $form_field (@$form_fields) {
        <td>
          <%= $item->{<%%= $form_field %%>} %>
        </td>
        %% }
        <td>
          <%= link_to 'Edit' => '<%%= $res_name %%>_update_form', { id => $item->{id} } %>
        </td>
        <td>
          <%= link_to 'View' => '<%%= $res_name %%>_show', { id => $item->{id} } %>
        </td>
    </tr>
    % }
    % if (!$<%%= $res_name_last %%> || !@$<%%= $res_name_last %%>) {
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
%% my $res_name    = shift;
%% my $form_fields = shift;
% layout 'resourceful_layout', title => 'Show';
<h1>Show one item of <%%= $res_name %%></h2><br />

<table>
    %% foreach my $form_field (@$form_fields) {
    <tr>
        <td>
            <%%=$form_field%%>
        </td>
        <td>
            <%= $item->{<%%=$form_field%%>} %>
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
%% my $res_name = shift;
%% my $form_fields = shift;
%% my $form_fields_type = shift;
% layout 'resourceful_layout', title => 'Create Form';

<h1>Create a new item of <%%= $res_name %%></h2><br />
<%= form_for '<%%= $res_name %%>_create', method => 'post' => begin %>
  %% foreach my $field (@$form_fields) {
  %% if ($form_fields_type->{$field} eq 'string' || $form_fields_type->{$field} eq 'int') {
    <%%= $field %%>:<br />
    <%= text_field '<%%= $field %%>', value => '' %><br /><br />
  %% }
  %% elsif ($form_fields_type->{$field} eq 'text') {
    <%%= $field %%>:<br />
    <%= text_area <%%= $field %%> => begin %><% end %><br /><br />
  %% }
  %% }
    <%= submit_button 'Create' %>
<% end %>

<br />
<%= link_to 'Index' => '<%%= $res_name %%>_index' %>
<%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>


%%############################################################################
@@ update_form
%% my $res_name = shift;
%% my $form_fields = shift;
%% my $form_fields_type = shift;
% layout 'resourceful_layout', title => 'Update Form';

<h1>Edit one item of <%%= $res_name %%></h2><br />

<%= form_for '<%%= $res_name %%>_update', method => 'post' => begin %>
  %% foreach my $field (@$form_fields) {
  %% if ($form_fields_type->{$field} eq 'string' || $form_fields_type->{$field} eq 'int') {
    <%%= $field %%>:<br />
    <%= text_field '<%%= $field %%>', value => $item->{<%%= $field %%>} %><br /><br />
  %% }
  %% elsif ($form_fields_type->{$field} eq 'text') {
    <%%= $field %%>:<br />
    <%= text_area <%%= $field %%> => begin %><%=$item->{<%%= $field %%>}%><% end %><br /><br />
  %% }
  %% }
    <%= hidden_field '_method' => 'put' %><br />
    <%= submit_button 'Update' %>
<% end %>

<br />
<%= link_to 'Index' => '<%%= $res_name %%>_index' %>
<%= link_to 'New'   => '<%%= $res_name %%>_create_form' %>


%%############################################################################
@@ resourceful_layout
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
%% my $resource = shift;
%% my $form_fields = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @$form_fields);
%% my @res_name_parts = split(/-/,$resource->{name});
%% my $res_name_last = $res_name_parts[-1];
package <%%= $resource->{class} %%>;

use strict;
use warnings;

use base 'Mojolicious::Controller';

# can be deleted after you have implemented your database
my @<%%= $res_name_last %%>;
my $counter = 0;


sub index {
    my $self = shift;
    # Read all resource items from a database
    # to make them available in the template index.html.ep
    # Save each row from the DB into a hash (column name is hash key, column value is hash value)
    # and push the hash reference into an array

    $self->stash(<%%= $res_name_last %%> => \@<%%= $res_name_last %%> );

}


sub show {
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $res_name_last %%>[$id-1];

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
    my $item = $<%%= $res_name_last %%>[$id-1];

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

    # save row to <%%= $res_name_last %%> hash
    push @<%%= $res_name_last %%>, {%data};


    # and redirect to "show" in order to display the created resource
    $self->redirect_to('<%%= $resource->{name} %%>_show', id => $counter );

}


sub update {
    my $self = shift;

    # Read ID passed via URL from stash
    my $id = $self->stash('id');

    # Read existing data from a database (from hash for sake of simplicity in this example)
    my $item = $<%%= $res_name_last %%>[$id-1];

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
@@ config
% my $config = shift;
%= $config

__END__
