package Mojolicious::Command::Generate::Scaffold;

use strict;
use warnings;

use base 'Mojo::Command';

use Mojo::ByteStream;
use Mojo::Server;

__PACKAGE__->attr(resource => sub {{}});

__PACKAGE__->attr(description => <<'EOF');
Generate a resource
EOF
__PACKAGE__->attr(usage => <<"EOF");
usage: $0 generate resource [APP_NAME RESOURCE_NAME FIELD_NAME:TYPE -OPTION:VALUE]
EOF


### mojolicious generate resource MyApp resource_name
sub run {
    my $self = shift;

    $self->config_base;

    $self->prompt('resource_name_plural');
    $self->prompt('tmpl_path');
    $self->prompt('ctrl_path');
    $self->prompt('resource_name_singular');
    $self->prompt('field_names');
    $self->prompt('model');


    # Validate paths
    $self->validate_paths();


    # Unique id and form fields
    $self->process_unique_key;
    $self->process_fields();


    # Create Model
    $self->create_model();


    # Create Templates
    $self->create_templates();


    # Change tags
    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');

    my $resource = $self->resource;


    print qq|\n\nWrite Files\n--------------------\n|;

    my $tmpl_path       = $resource->{tmpl}->{path};
    my $layout_path     = $resource->{layout}->{path};
    my $model_path      = $resource->{model}->{path};
    my $model_base_path = $resource->{model}->{base_path};

    # Controller file
    if ( $self->overwrite_ctrl_path ) {
        $self->render_to_rel_file('controller', $resource->{ctrl}->{path}, $resource);
    }


    # Test file
    $self->render_to_rel_file('test', $resource->{test}->{path}, $resource);


    # Layout file
    $self->render_to_rel_file('layout',      $layout_path.'/resources.html.ep', $resource);


    # Template files
    if ( $self->overwrite_tmpl_path ){
        $self->render_to_rel_file('index',       $tmpl_path.'/index.html.ep', $resource);
        $self->render_to_rel_file('show',        $tmpl_path.'/show.html.ep', $resource);
        $self->render_to_rel_file('new_form',    $tmpl_path.'/new_form.html.ep', $resource);
        $self->render_to_rel_file('edit_form',   $tmpl_path.'/edit_form.html.ep', $resource);
    }


    # Model files
    $self->render_to_rel_file('source', $model_path, $resource);

    $self->render_to_rel_file('model_base_class', $model_base_path, $resource)
        unless (-e $model_base_path);



    # To do infos:
    print qq|\n\nTO DOs\n--------------------\n|;
    print qq|Make sure that the following commands can be found in the |;
    print qq|startup method of your routing file:\n|;
    print qq|                                           \n|;
    print qq|    ### Plugins                            \n|;
    print qq|    \$self->plugin('resourceful_routes');  \n|;
    print qq|    \$self->plugin('model_instance', namespace => '$resource->{model}->{namespace}', method => '$resource->{model}->{code}->{instance_accessor}');\n|;
    print qq|                                           \n|;
    print qq|    ### Resources                          \n|;
    print qq|    \$self->resources('$resource->{name}');\n|;
    print qq|                                           \n|;
    print qq|You can also use the following code for MySQL or modify it for other database systems:\n|;
    print $self->generate_sql;
    print qq|                                           \n|;
    print qq|Make sure that you put the correct config in the database base file:\n|;
    print qq|    $resource->{model}->{base_path}        \n|;


}


sub generate_sql {
    my $self = shift;

    my $db_type = {
        text    => 'text',
        string  => 'varchar(255)',
        int     => 'int'
    };

    my $resource = $self->resource;

    my $sql = '    create table ';
    $sql .= $resource->{model}->{items_name};
    $sql .= qq| (\n|;

    $sql .= qq|        $resource->{unique_key} $db_type->{$resource->{unique_key_type}} auto_increment primary key,\n|;

    foreach my $field (@{$resource->{form_fields}}) {
        $sql .= qq|        $field->{name} $db_type->{$field->{type}},\n|;
    }
    chomp $sql;
    chop $sql;

    $sql .= qq|\n    );|;

}


sub prompt {
    my $self     = shift;
    my $name     = shift;
    my $err_msg  = shift;

    my $resource = $self->resource;

    my %description;

    $description{field_names} =
        qq|\n\nField names\n--------------------\n| .
        qq|Format:      field_name:field_type\n| .
        qq|Valid types: string, text, int\n| .
        qq|Example:     first_name:string age:int description:text\n| .
        qq|Enter:       |;

    $description{resource_name_plural} =
        qq|\n\nPlural resource name\n--------------------\n| .
        qq|Format:      lowercase\n| .
        qq|Example:     users\n| .
        qq|Enter:       |;

    $description{resource_name_singular} =
        qq|\n\nSingular resource name\n--------------------\n| .
        qq|Format:      lowercase\n| .
        qq|Example:     user\n| .
        qq|Enter:       |;

    $description{model} =
        qq|\n\nModel\n--------------------\n| .
        qq|Available models: d_b_i object_d_b\n| .
        qq|Example:          d_b_i\n| .
        qq|Enter:            |;

    $description{tmpl_path} =
        qq|\n\nOverwrite template files\n--------------------\n| .
        qq|Template path $resource->{tmpl}->{path} already exists.\n| .
        qq|Overwrite [yes/no]:   | if $resource->{tmpl}->{path};

    $description{ctrl_path} =
        qq|\n\nOverwrite controller file\n--------------------\n| .
        qq|Controller path $resource->{ctrl}->{path} already exists.\n| .
        qq|Overwrite [yes/no]:   | if $resource->{ctrl}->{path};


    # Pre check
    if ($name eq 'tmpl_path') {
        return if defined $self->overwrite_tmpl_path;
    }
    elsif ($name eq 'ctrl_path') {
        return if defined $self->overwrite_ctrl_path;
    }

    # Print error message or description
    print $err_msg || $description{$name};
    $| = 1;
    my $input = <STDIN>;
    chomp $input;


    # Split input in array
    $input =~s/  //g;
    $input =~s/^ //g;
    $input =~s/ $//g;
    my @params = split(/ /, $input);


    # Start validation
    my $validation_method = 'validate_'.$name;
    $err_msg = $self->$validation_method(\@params);


    # New prompt in case of error
    if ( $err_msg ) {
        $self->prompt($name, $err_msg);
    }

}

sub process_fields {
    my $self = shift;

    my $resource = $self->resource;

    my $unique_key  = $resource->{unique_key};
    my $data_fields = $resource->{data_fields};

    # Form fields
    my @form_fields;
    my @form_field_names;
    foreach my $field (@$data_fields){
        unless ($field->{name} eq $unique_key) {
            push @form_fields, $field;
            push @form_field_names, $field->{name};
        }
    }

    $resource->{form_fields}      = [@form_fields];
    $resource->{form_field_names} = [@form_field_names];
}


sub process_unique_key {
    my $self = shift;

    my $resource = $self->resource;

    my $data_fields = $resource->{data_fields};
    my $unique_key  = $resource->{unique_key};

    # No unique key passed
    $unique_key = 'id' unless defined $unique_key;

    my $unique_key_type;
    foreach my $field (@$data_fields){
        if ($field->{name} eq $unique_key) {
            $unique_key_type = $field->{type};
        }
    }

    # No unique key type passed
    $unique_key_type = 'int' unless defined $unique_key_type;

    $resource->{unique_key}      = $unique_key;
    $resource->{unique_key_type} = $unique_key_type;

}


sub validate_field_names {
    my $self     = shift;
    my $params   = shift;

    my $resource = $self->resource;

    my $valid_data_types = {
        'int'    => 1,
        'string' => 1,
        'text'   => 1,
    };

    my @data_fields;

    unless (@$params) {
        return
            qq|\n\nERROR: Enter at least one form field! | .
            qq|\n\nTry again:|;
    }

    foreach my $param (@$params){
        # Cleanup
        chomp $param;

        # Validate general format
        if ($param !~m/^-{0,1}[\w]+:[\w-]+$/){
            return
                qq|\n\nERROR: format of parameters has to be: "name:type", | .
                qq|no spaces, just alphanumeric and "_" (underscore), | .
                qq|malformed parameter >> "$param"| .
                qq|\n\nTry again:|;
        }

        # Split data
        my ($name, $type) = split(/:/, $param );

        # Validate form field
        if (!$valid_data_types->{$type}){
            return
                qq|wrong format "$type", format can be: |.
                join(', ', map {'"'.$_.'"'} keys %$valid_data_types).
                qq|, malformed parameter >> "$param"| .
                qq|\n\nTry again: |;
        }


        push @data_fields, {
            name                 => $name,
            type                 => $type,
            sample_data          => sample_data_by_type($name,$type),
            sample_data_modified => sample_data_by_type($name,$type,1),
        };

    }

    # Save to resource
    $resource->{data_fields}   = [@data_fields];

    return undef;

}


sub validate_resource_name_plural {
    my $self     = shift;
    my $params   = shift;

    my $resource = $self->resource;

    unless ($params->[0] && $params->[0] =~m/^[a-z0-9-]+$/) {
        return
            qq|ERROR: Please enter a valid resource name!\n| .
            qq|\nTry again:   |;
    }

    # Save resource name
    $resource->{name} = $params->[0];
    my @resource_name_parts = split(/-/, $resource->{name});
    $resource->{last_name}  = $resource_name_parts[-1];

    # Get paths based on plural name
    $self->config_ctrl;
    $self->config_view;
    $self->config_test;

    return undef;

}


sub overwrite_tmpl_path {
    my $self   = shift;

    my $resource = $self->resource;

    # Make sure template path does not already exists
    if ( -e $resource->{tmpl}->{path} && !$resource->{tmpl}->{overwrite}){
        return undef;
    }
    elsif ( -e $resource->{tmpl}->{path} && $resource->{tmpl}->{overwrite} eq 'yes' ){
        return 1;
    }
    elsif ( -e $resource->{tmpl}->{path} && $resource->{tmpl}->{overwrite} eq 'no' ){
        return 0;
    }
    else {
        return 1;
    }

}


sub validate_tmpl_path {
    my $self   = shift;
    my $params = shift;

    my $resource = $self->resource;

    $params->[0] ||= 0;

    if ($params->[0] eq 'yes') {
        $resource->{tmpl}->{overwrite} = 'yes';
    }
    elsif ($params->[0] eq 'no') {
        $resource->{tmpl}->{overwrite} = 'no';
    }
    else {
        return "\nEnter yes or no:   ";
    }

    return undef;

}


sub overwrite_ctrl_path {
    my $self   = shift;

    my $resource = $self->resource;

    # Make sure template path does not already exists
    if ( -e $resource->{ctrl}->{path} && !$resource->{ctrl}->{overwrite}){
        return undef;
    }
    elsif ( -e $resource->{ctrl}->{path} && $resource->{ctrl}->{overwrite} eq 'yes' ){
        return 1;
    }
    elsif ( -e $resource->{ctrl}->{path} && $resource->{ctrl}->{overwrite} eq 'no' ){
        return 0;
    }
    else {
        return 1;
    }

}


sub validate_ctrl_path {
    my $self   = shift;
    my $params = shift;

    my $resource = $self->resource;

    $params->[0] ||= 0;

    if ($params->[0] eq 'yes') {
        $resource->{ctrl}->{overwrite} = 'yes';
    }
    elsif ($params->[0] eq 'no') {
        $resource->{ctrl}->{overwrite} = 'no';
    }
    else {
        return "\nEnter yes or no:   ";
    }

    return undef;

}


sub validate_paths {
    my $self = shift;

    my $resource = $self->resource;

    my $tmpl_base = $resource->{tmpl}->{base_path};

    # Make sure template path exists
    unless ( -e $tmpl_base ){
        die qq|Template path "$tmpl_base" not found! Make sure that you |.
            qq|switch to the directory where your application is located |.
            qq|before running "script/myapp generate resource"!|;
    }
}


sub validate_resource_name_singular {
    my $self     = shift;
    my $params   = shift;

    my $resource = $self->resource;

    unless ($params->[0] && $params->[0] =~m/^[a-z0-9-]+$/) {
        return
            qq|ERROR: Please enter the singular form for resource name!\n| .
            qq|\nTry again:   |;
    }

    $resource->{name_singular} = $params->[0];

    return undef;

}

sub validate_model {
    my $self   = shift;
    my $params = shift;

    my $resource = $self->resource;

    my $valid_orms = {
        object_d_b => 1,
        d_b_i      => 1,
    };

    unless ($params->[0]) {
        return
            qq|ERROR: Please select an orm!\n| .
            qq|Available models: | .
            join(', ', keys %$valid_orms) .
            qq|\nTry again:|;
    }

    unless ($valid_orms->{$params->[0]}) {
        return
            qq|ERROR: unknow model\n| .
            qq|Available models: | .
            join(', ', keys %$valid_orms) .
            qq|\nTry again:|;
    }

    # Save to resource
    $resource->{orm_name} = $params->[0];

    $self->config_model();

    return undef;

}


sub sample_data_by_type {
    my $name     = shift;
    my $type     = shift;
    my $modified = shift;

    if ($type eq 'string' || $type eq 'text'){
        return $name.'_value' unless $modified;
        return $name.'_value_modified';
    }
    elsif ($type eq 'int'){
        return 13 unless $modified;
        return 14;
    }

    1;
}

sub config_base {
    my $self = shift;

    # Get resource hash ref
    my $resource = $self->resource;

    # App instance
    my $app = Mojo::Server->new->app || die 'app not found';

    # App name
    my $namespace = $app->routes->namespace;
    my @namespace = split(/::/, $namespace);

    $resource->{app}->{name} = $namespace[0];

    unless (@namespace > 1 && $namespace[1] eq 'Controllers'){
    print
        qq|\n\nNotice\n--------------------\n| .
        qq|It is recommended to put your controllers in a separate folder,\n| .
        qq|so instead of lib/$resource->{app}->{name}, controllers could be located under\n| .
        qq|lib/$resource->{app}->{name}/Controllers, in order to do this, add\n| .
        q|    $self->routes->namespace('|.$resource->{app}->{name}.qq|::Controllers');| .
        qq|\nto the startup method in your routes file (located in the lib folder)|;
        qq|\nbefore going ahead (use Strg + C to exit)|;
    }

}

sub config_ctrl {
    my $self = shift;

    # Get resource hash ref
    my $resource = $self->resource;

    # App instance
    my $app = Mojo::Server->new->app || die 'app not found';

    # Controller namespace
    my $namespace = $app->routes->namespace;

    # Controller class
    my $ctrl_class = $namespace.'::'.Mojo::ByteStream->new($resource->{name})
      ->camelize->to_string;

    # Controller path
    my $ctrl_path = 'lib/'.$self->class_to_path($ctrl_class);

    $resource->{ctrl}->{class}     = $ctrl_class;
    $resource->{ctrl}->{path}      = $ctrl_path;
    $resource->{ctrl}->{namespace} = $namespace;

}

sub config_test {
    my $self = shift;

    # Get resource hash ref
    my $resource = $self->resource;

    # Test path
    my $test_path = '/t/'.join('/', split(/-/, $resource->{name}) ).'/standard.t';

    # Dispatch path
    my $dispatch_path = '/'.join('/', split(/-/, $resource->{name}) );

    # Save to resource
    $resource->{test}->{path}          = $test_path;
    $resource->{test}->{dispatch_path} = $dispatch_path;

}

sub config_view {
    my $self     = shift;

    # Get resource hash ref
    my $resource = $self->resource;

    # Template base path
    my $app = Mojo::Server->new->app || die 'app not found';
    my $tmpl_base = $app->renderer->root;

    # Template path
    my $tmpl_sub_path = join('/', split(/-/, $resource->{name}) );
    my $tmpl_path     = $tmpl_base.'/'.$tmpl_sub_path;

    # Layout path
    my $layout_path = $tmpl_base.'/layouts';

    # Save paths to resource hash ref
    $resource->{tmpl}->{path}      = $tmpl_path;
    $resource->{tmpl}->{base_path} = $tmpl_base;
    $resource->{layout}->{path}    = $layout_path;
    $resource->{tmpl}->{overwrite} = 0;

}

sub config_model {
    my $self = shift;

    # Get resource hash ref
    my $resource = $self->resource;

    # Get ORM and app name
    my $orm_name = $resource->{orm_name};
    my $app_name = $resource->{app}->{name};

    # Scalar name for one item
    my $item_name = $resource->{name_singular};
    $item_name =~s/-/_/;

    # Scalar name for multiple items
    my $items_name = $resource->{name};
    $items_name =~s/-/_/;

    # Generate ORM scaffolder class
    my $orm = 'MojoX::Scaffold::Model::'.Mojo::ByteStream->new($orm_name)
      ->camelize->to_string;

    # Load ORM scaffolder class
    Mojo::Loader->new->load($orm);

    # Create new ORM scaffolder class instance
    my $scaff = $orm->new(resource => $resource);

    # Get default namespace from ORM scaffolder
    my $model_namespace = $scaff->default_namespace;

    # File name of model class
    my $model_class_last = Mojo::ByteStream->new($item_name)->camelize->to_string;

    # Model class and path
    my $model_class = $model_namespace.'::'.$model_class_last;
    my $model_path  = 'lib/'.$self->class_to_path($model_class);

    # Model base class and path (subclass of the real ORM class)
    my $model_base_class = $scaff->default_base_class;
    my $model_base_path  = 'lib/'.$self->class_to_path($model_base_class);

    # Save paths to resource hash ref
    $resource->{model}->{item_name}  = $item_name;
    $resource->{model}->{items_name} = $items_name;
    $resource->{model}->{namespace}  = $model_namespace;
    $resource->{model}->{class_last} = $model_class_last;
    $resource->{model}->{class}      = $model_class;
    $resource->{model}->{path}       = $model_path;
    $resource->{model}->{base_class} = $model_base_class;
    $resource->{model}->{base_path}  = $model_base_path;

}


sub create_model {
    my $self = shift;

    # Get resource
    my $resource = $self->resource;

    # Get scaffolder class
    my $scaff_class = 'MojoX::Scaffold::Model::'.Mojo::ByteStream
      ->new($resource->{orm_name})->camelize->to_string;

    # Load ORM scaffolder class
    Mojo::Loader->new->load($scaff_class);

    # Create new instance
    my $scaff = $scaff_class->new(resource => $resource);

    # Get jigsaw pieces
    my $code = $resource->{model}->{code} = {};
    $code->{class_data}       = $scaff->class_data;
    $code->{index}            = $scaff->index;
    $code->{show}             = $scaff->show;
    $code->{new_form}         = $scaff->new_form;
    $code->{edit_form}        = $scaff->edit_form;
    $code->{create}           = $scaff->create;
    $code->{update}           = $scaff->update;
    $code->{delete}           = $scaff->delete;
    $code->{source}           = $scaff->source;
    $code->{base_class}       = $scaff->base_class;
    $code->{loop}             = $scaff->loop;
    $code->{item_accessor}    = $scaff->item_accessor;
    $code->{number_of_rows}   = $scaff->number_of_rows;
    $code->{instance_accessor} = $scaff->instance_accessor;

}


sub create_templates {
    my $self     = shift;

    # Get resource
    my $resource = $self->resource;

    # Get scaffolder class
    my $tmpl = $resource->{options}->{tmpl} || 'embedded_perl';
    my $scaff_class = 'MojoX::Scaffold::Template::'.Mojo::ByteStream
      ->new($tmpl)->camelize->to_string;

    # Load template scaffolder class
    Mojo::Loader->new->load($scaff_class);

    my $scaff = $scaff_class->new(resource => $resource);

    # Get jigsaw pieces
    my $code = $resource->{tmpl}->{code} = {};
    $code->{index}       = $scaff->index;
    $code->{show}        = $scaff->show;
    $code->{new_form}    = $scaff->new_form;
    $code->{edit_form}   = $scaff->edit_form;
    $code->{layout}      = $scaff->layout;

}

1;


__DATA__


%%############################################################################
@@ index
%% my $resource = shift;
<%%= $resource->{tmpl}->{code}->{index} %%>


%%############################################################################
@@ show
%% my $resource = shift;
<%%= $resource->{tmpl}->{code}->{show} %%>


%%############################################################################
@@ new_form
%% my $resource = shift;
<%%= $resource->{tmpl}->{code}->{new_form} %%>


%%############################################################################
@@ edit_form
%% my $resource = shift;
<%%= $resource->{tmpl}->{code}->{edit_form} %%>


%%############################################################################
@@ layout
%% my $resource = shift;
<%%= $resource->{tmpl}->{code}->{layout} %%>


%%############################################################################
@@ controller
%% my $resource = shift;
%% my $form_fields_list = join (',', map { '"'.$_.'"' } @{$resource->{form_field_names}});
%% my $res_last_name    = $resource->{last_name};
package <%%= $resource->{ctrl}->{class} %%>;

use strict;
use warnings;

use base 'Mojolicious::Controller';

<%%= $resource->{model}->{code}->{class_data} %%>


sub index {
<%%= $resource->{model}->{code}->{index} %%>
}


sub show {
<%%= $resource->{model}->{code}->{show} %%>
}


sub new_form {
<%%= $resource->{model}->{code}->{new_form} %%>
}


sub edit_form {
<%%= $resource->{model}->{code}->{edit_form} %%>
}


sub create {
<%%= $resource->{model}->{code}->{create} %%>
    # and redirect to "show" in order to display the created resource
    $self->redirect_to('<%%= $resource->{name} %%>_show', id => $id );

}


sub update {
<%%= $resource->{model}->{code}->{update} %%>
    # redirect to "show" in order to display the updated resource
    $self->redirect_to('<%%= $resource->{name} %%>_show', id => $id );

}


sub delete {
<%%= $resource->{model}->{code}->{delete} %%>
}

1;


%%############################################################################
@@ source
%% my $resource = shift;
<%%= $resource->{model}->{code}->{source} %%>


%%############################################################################
@@ model_base_class
%% my $resource = shift;
<%%= $resource->{model}->{code}->{base_class} %%>


%%############################################################################
@@ test
%% my $resource             = shift;
%% my @form_fields          = @{$resource->{form_fields}};
%% my $dispatch_path        = $resource->{test}->{dispatch_path};
%% my $test_num             = 16 + @form_fields * 5;
%% my $sample_data          = join(",\n    ", map { $_->{name}." => '".$_->{sample_data}."'" } @form_fields);
%% my $sample_data_modified = join(",\n    ", map { $_->{name}." => '".$_->{sample_data_modified}."'" } @form_fields);
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

plan tests => <%%= $test_num %%>;

my $t = Test::Mojo->new(app => '<%%= $resource->{app}->{name} %%>');

# Sample Data
my $sample_data = {
    <%%= $sample_data %%>
};

my $sample_data_modified = {
    _method => 'put', # NEEDED TO TRANSFORM POST TO PUT REQUESTS
    <%%= $sample_data_modified %%>
};


### GET new_form
$t->get_ok('<%%= $dispatch_path %%>/new')
  ->status_is(200);

%% foreach my $field (@form_fields) {
    %% if ($field->{type} eq 'text') {
$t->text_is('textarea[name="<%%= $field->{name} %%>"]' => '');
    %% }
    %% else {
$t->element_exists('input[name="<%%= $field->{name} %%>"]');
    %% }
%% }


### POST create
$t->post_form_ok('<%%= $dispatch_path %%>', $sample_data)
  ->status_is(302) # redirect
  ->header_like('location' => qr|<%%= $dispatch_path %%>/(\w)|);


# Get generated ID from redirect URL
my $redirect = scalar $t->tx->res->headers->header('location');
$redirect =~m/\/([\w]+)$/;
my $id = $1;


### GET show
$t->get_ok("<%%= $dispatch_path %%>/$id")
  ->status_is(200);

%% foreach my $field (@form_fields) {
%%    my $search_value = quotemeta($field->{sample_data});
$t->content_like(qr/<%%= $search_value %%>/s);
%%}


### GET index
$t->get_ok('<%%= $dispatch_path %%>')
  ->status_is(200);

%% foreach my $field (@form_fields) {
%%    my $search_value = quotemeta($field->{sample_data});
$t->content_like(qr/<%%= $search_value %%>/s);
%%}


### GET edit_form
$t->get_ok("<%%= $dispatch_path %%>/$id/edit")
  ->status_is(200);

%% foreach my $field (@form_fields) {
    %% if ($field->{type} eq 'text') {
$t->text_is('textarea[name="<%%= $field->{name} %%>"]' => "<%%= $field->{sample_data} %%>");
    %% }
    %% else {
$t->element_exists('input[name="<%%= $field->{name} %%>"][value="<%%= $field->{sample_data} %%>"]');
    %% }
%% }


### PUT update
$t->post_form_ok("<%%= $dispatch_path %%>/$id", $sample_data_modified)
  ->status_is(302)
  ->header_like('location' => qr|<%%= $dispatch_path %%>/$id|);


### GET show
$t->get_ok("<%%= $dispatch_path %%>/$id")
  ->status_is(200);

%% foreach my $field (@form_fields) {
%%    my $search_value = quotemeta($field->{sample_data_modified});
$t->content_like(qr/<%%= $search_value %%>/s);
%% }


1;


%%############################################################################
@@ config
% my $config = shift;
%= $config

__END__
