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

sub new_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('new_form', $self->resource);
}

sub edit_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('edit_form', $self->resource);
}

sub delete_form {
    my $self = shift;
    $self->change_tags;
    return $self->render_data('delete_form', $self->resource);
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
%% my $form_fields    = $resource->{form_fields};
%% my $item_accessor  = $resource->{model}->{code}->{item_accessor};

    % layout 'resources', title => 'Index';
    <h1>List <%%= $resource->{name} %%></h1><br />

    % if (my $message = flash 'message' ) {
        <div class="flash"><%= $message %></div><br />
    % }

    <table>
      <tr>
        %% foreach my $form_field (@$form_fields) {
        <th><%%= $form_field->{name} %%></th>
        %% }
        <th>Edit</th>
        <th>View</th>
        <th>Delete</th>
      </tr>
      % <%%= $resource->{model}->{code}->{loop} %%>
      <tr>
        %% foreach my $form_field (@$form_fields) {
        <td><%= <%%= $item_accessor->($form_field->{name}) %%> %></td>
        %% }
        <td>
          <%= link_to 'Edit' => '<%%= $resource->{name} %%>_edit_form', { id => <%%= $item_accessor->('id') %%> } %>
        </td>
        <td>
          <%= link_to 'View' => '<%%= $resource->{name} %%>_show', { id => <%%= $item_accessor->('id') %%> } %>
        </td>
        <td>
          <%= link_to 'Delete' => '<%%= $resource->{name} %%>_delete_form', { id => <%%= $item_accessor->('id') %%> } %>
        </td>
      </tr>
      % }
      % unless ( <%%= $resource->{model}->{code}->{number_of_rows} %%> ) {
      <tr>
        <td colspan="<%%= @$form_fields+3 %%>">No Results</td>
      </tr>
      % }
    </table>

    <br />
    <%= link_to 'Index' => '<%%= $resource->{name} %%>_index' %>
    <%= link_to 'New'   => '<%%= $resource->{name} %%>_new_form' %>



%%############################################################################
@@ show
%% my $resource    = shift;
%% my $form_fields   = $resource->{form_fields};
%% my $item_accessor = $resource->{model}->{code}->{item_accessor};

    % layout 'resources', title => 'Show';
    <h1>Show one item of <%%= $resource->{name} %%></h1><br />
    
    % if (my $message = flash 'message' ) {
        <div class="flash"><%= $message %></div><br />
    % }

    
    <table>
        %% foreach my $form_field (@$form_fields) {
        <tr>
            <td>
                <%%=$form_field->{name}%%>
            </td>
            <td>
                <%= <%%= $item_accessor->($form_field->{name}) %%> %>
            </td>
        </tr>
    
        %% }
    </table>

    <br />
    <%= link_to 'Index' => '<%%= $resource->{name} %%>_index' %>
    <%= link_to 'New'   => '<%%= $resource->{name} %%>_new_form' %>
    <%= link_to 'Edit'  => '<%%= $resource->{name} %%>_edit_form', { id => <%%= $item_accessor->('id') %%> } %>


%%############################################################################
@@ new_form
%% my $resource    = shift;
%% my $form_fields = $resource->{form_fields};

    % layout 'resources', title => 'Create Form';
    
    <h1>Create a new item of <%%= $resource->{name} %%></h1><br />
    <%= form_for '<%%= $resource->{name} %%>_create', method => 'post' => begin %>
      %% foreach my $field (@$form_fields) {
      %% if ($field->{type} eq 'string' || $field->{type} eq 'int') {
        <label for="<%%= $field->{name} %%>"><%%= $field->{name} %%></label>:<br />
        <%= text_field '<%%= $field->{name} %%>', id => "<%%= $field->{name} %%>", value => '' %><br /><br />
        
      %% }
      %% elsif ($field->{type} eq 'text') {
        <label for="<%%= $field->{name} %%>"><%%= $field->{name} %%></label>:<br />
        <%= text_area "<%%= $field->{name} %%>", id => "<%%= $field->{name} %%>" => begin %><% end %><br /><br />
        
      %% }
      %% }
        <%= submit_button 'Create' %>
    <% end %>
    
    <br />
    <%= link_to 'Index' => '<%%= $resource->{name} %%>_index' %>
    <%= link_to 'New'   => '<%%= $resource->{name} %%>_new_form' %>



%%############################################################################
@@ edit_form
%% my $resource      = shift;
%% my $form_fields   = $resource->{form_fields};
%% my $item_accessor = $resource->{model}->{code}->{item_accessor};
    % layout 'resources', title => 'Update Form';
    
    <h1>Edit one item of <%%= $resource->{name} %%></h1><br />
    
    <%= form_for '<%%= $resource->{name} %%>_update', {id => $id}, method => 'post' => begin %>
      %% foreach my $field (@$form_fields) {
      %% if ($field->{type} eq 'string' || $field->{type} eq 'int') {
        <label for="<%%= $field->{name} %%>"><%%= $field->{name} %%></label>:<br />
        <%= text_field '<%%= $field->{name} %%>', id => "<%%= $field->{name} %%>", value => <%%= $item_accessor->($field->{name}) %%> %><br /><br />
        
      %% }
      %% elsif ($field->{type} eq 'text') {
        <label for="<%%= $field->{name} %%>"><%%= $field->{name} %%></label>:<br />
        <%= text_area "<%%= $field->{name} %%>", id => "<%%= $field->{name} %%>" => begin %><%= <%%= $item_accessor->($field->{name}) %%> %><% end %><br /><br />
        
      %% }
      %% }
        <%= hidden_field '_method' => 'put' %><br />
        <%= submit_button 'Update' %>
    <% end %>
    
    <br />
    <%= link_to 'Index' => '<%%= $resource->{name} %%>_index' %>
    <%= link_to 'New'   => '<%%= $resource->{name} %%>_new_form' %>


%%############################################################################
@@ delete_form
%% my $resource      = shift;
    % layout 'resources', title => 'Update Form';
    
    <h1>Delete one item of <%%= $resource->{name} %%></h1><br />
    
    do you really want to delete this entry?
    <%= form_for '<%%= $resource->{name} %%>_delete', {id => $id}, method => 'post' => begin %>
        <%= hidden_field '_method' => 'delete' %><br />
        <%= submit_button 'Delete' %>
    <% end %>
    
    <br />
    <%= link_to 'Index' => '<%%= $resource->{name} %%>_index' %>
    <%= link_to 'New'   => '<%%= $resource->{name} %%>_new_form' %>


%%############################################################################
@@ layout
%% my $resource = shift;
<!doctype html>
  <html>
    <head>
      <meta charset="UTF-8">
      <title>
        <%= $title %>
      </title>
      <style type="text/css">
        body, p, th, td {
          font-family: arial, verdana, helvetica, sans-serif;
          font-size:   14px;
        }
        div.flash {
          font-family: arial, verdana, helvetica, sans-serif;
          font-size:   16px;
          color: #C30;
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
