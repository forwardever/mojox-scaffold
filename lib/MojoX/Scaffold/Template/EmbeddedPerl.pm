package MojoX::Scaffold::Template::EmbeddedPerl;

use strict;
use warnings;

use base 'MojoX::Scaffold::Template';

__PACKAGE__->attr('resource');


sub index {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('index', $self->resource);
}

sub show {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('show', $self->resource);

}

sub create_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('create_form', $self->resource);
}

sub update_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('update_form', $self->resource);
}

sub layout {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('layout', $self->resource);
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
%% my $resource = shift;
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


__END__
