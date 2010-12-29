package Mojolicious::Plugin::ResourcefulRoutes;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

our $VERSION = '0.04';

sub register {
    my ($self, $app) = @_;

    $app->hook(
        before_dispatch => sub {
            my $c = shift;

            if ($c->req->method eq 'POST') {
                my $method = lc($c->req->param('_method') || '');
                if ($method eq 'delete') {
                    $c->req->method('DELETE');
                }
                elsif ($method eq 'put') {
                    $c->req->method('PUT');
                }
            }
        }
    );

    $app->helper(
        resource => sub {
            my ($c, $resource, $options) = @_;
            die
              'ResourcefulRoutes: options have to be passed as hash ref, use'
              . ' "resources" (plural) to define multiple resources at once:'
              . ' resource name: '
              . $resource
              . ', passed options: '
              . $options
              unless ref $options eq 'HASH' || !$options;
            $self->generate_routes($c, $resource, $options);
        }
    );

    $app->helper(
        resources => sub {
            my $c      = shift;
            my @params = @_;

            my %valid_option = (
                '-except'   => 1,
                '-only'     => 1,
                '-singular' => 1
            );

            # Options
            while (@params) {
                my $options  = {};

                my $resource = shift(@params) if @params;

                while (@params) {
                    # hashref
                    if (@params && ref $params[0] eq 'HASH'){
                        $options = shift(@params);
                    }
                    elsif (@params && $valid_option{$params[0]}) {
                        $params[0] =~ s/^-//;
    
                        my $key   = shift(@params);
                        my $value = shift(@params);
    
                        $options->{$key} = $value;
                    }
                    else {
                        last;
                    }
                }

                $self->generate_routes($c, $resource, $options);

            }

        }
    );
}

sub generate_routes {
    my $self = shift;
    my ($c, $resource, $options) = @_;

    my $singular = $options->{singular};


    # Except and only
    my $except = $options->{except};
    my $only   = $options->{only};

    die
      q/ResourcefulRoutes: you can include OR exclude routes with "only" OR "except", dont use both for one resource!/
      if defined $except and $only;

    # Default
    my %valid = (
        index       => 1,
        show        => 1,
        new_form    => 1,
        edit_form   => 1,
        delete_form => 1,
        create      => 1,
        update      => 1,
        delete      => 1
    );

    foreach my $r (@$except) {
        die qq/ResourcefulRoutes: invalid param "$r" used in "except"/
          unless exists $valid{$r};
        $valid{$r} = 0;
    }

    my %valid_only;
    foreach my $r (@$only) {
        die qq/ResourcefulRoutes: invalid param "$r" used in "only"/
          unless exists $valid{$r};
        $valid_only{$r} = 1;
    }
    %valid = %valid_only if @$only;


    # Create path for routes
    my $path = join('/', split(/-/, $resource));


    # Resource name is part of the route name
    my $name = $resource;


    # Create controller path
    my $ctrl = $resource;


    # Get routes object
    my $r = $c->app->routes;


    # Singular resource, i.e. app knows id value (e.g. from login)
    if ($singular) {

        my $nr = $r->route("$path");

        # GET /article/new - form for create an article
        $nr->route('/new')->via('get')
          ->to(controller => $ctrl, action => 'new_form')
          ->name($name . '_new_form')
          if $valid{new_form};

        # GET /article - show article
        $nr->route('/')->via('get')->to(controller => $ctrl, action => 'show')
          ->name($name . '_show')
          if $valid{show};

        # GET /article/edit - form for update an article
        $nr->route('/edit')->via('get')
          ->to(controller => $ctrl, action => 'edit_form')
          ->name($name . '_edit_form')
          if $valid{edit_form};

        # GET /article/delete - form to confirm delete
        $nr->route('/delete')->via('get')
          ->to(controller => $ctrl, action => 'delete_form')
          ->name($name . '_delete_form')
          if $valid{delete_form};

        # POST /article - create article
        $nr->route('/')->via('post')
          ->to(controller => $ctrl, action => 'create')
          ->name($name . '_create')
          if $valid{create};

        # PUT /article - update article
        $nr->route('/')->via('put')
          ->to(controller => $ctrl, action => 'update')
          ->name($name . '_update')
          if $valid{update};

        # DELETE /article - delete article
        $nr->route('/')->via('delete')
          ->to(controller => $ctrl, action => 'delete')
          ->name($name . '_delete')
          if $valid{delete};

    }

    # Id passed via URL
    else {

        my $nr = $r->route("$path");

        # GET /articles/new - form for create an article
        $nr->route('/new')->via('get')
          ->to(controller => $ctrl, action => 'new_form')
          ->name($name . '_new_form')
          if $valid{new_form};

        # GET /articles/123 - show article with id 123
        $nr->route('/:id')->via('get')
          ->to(controller => $ctrl, action => 'show')->name($name . '_show')
          if $valid{show};

        # GET /articles/123/delete - form to confirm delete
        $nr->route('/:id/delete')->via('get')
          ->to(controller => $ctrl, action => 'delete_form')
          ->name($name . '_delete_form')
          if $valid{delete_form};

        # GET /articles/123/edit - form for update an article
        $nr->route('/:id/edit')->via('get')
          ->to(controller => $ctrl, action => 'edit_form')
          ->name($name . '_edit_form')
          if $valid{edit_form};

        # GET /articles - list of all articles
        $nr->route('/')->via('get')
          ->to(controller => $ctrl, action => 'index')->name($name . '_index')
          if $valid{index};

        # POST /articles - create new article
        $nr->route('/')->via('post')
          ->to(controller => $ctrl, action => 'create')
          ->name($name . '_create')
          if $valid{create};

        # PUT /articles/123 - update article
        $nr->route('/:id')->via('put')
          ->to(controller => $ctrl, action => 'update')
          ->name($name . '_update')
          if $valid{update};

        # DELETE /articles/123 - delete article
        $nr->route('/:id')->via('delete')
          ->to(controller => $ctrl, action => 'delete')
          ->name($name . '_delete')
          if $valid{delete};
    }
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::ResourcefulRoutes

=head1 SYNOPSIS

    sub startup {
        my $self = shift;

        # Create "cities" and "admin-cities" resources
        $self->plugin('resourceful_routes');
        $self->resources('cities', -except => ['delete', 'delete_form'] , 'admin-cities' );
   
    }

=head1 DESCRIPTION

L<Mojolicious::Plugin::ResourcefulRoutes> allows you to define a bunch of
routes with a single command.

For example, in order to manage a list of cities, you need routes to
    - list all cities,
    - display information on a single city,
    - display forms to create, update and delete cities
    - and to finally create, update and delete cities.

Routes are created based on naming conventions. Depending on the HTTP request
method and the request path, users are dispatched to a specific controller
method. In addition to that, each route gets a name.

$self->resources('cities') automatically generates the following
routes on each start of your app.

    HTTP     URL (not including      Contoller   Method          Route Name
    request  http://localhost:3000)
    method          

    GET      /cities/new             Cities      new_form        cities_new_form
    GET      /cities/paris           Cities      show            cities_show
    GET      /cities/paris/edit      Cities      edit_form       cities_edit_form
    GET      /cities/paris/delete    Cities      delete_form     cities_delete_form
    GET      /cities                 Cities      index           cities_index
    POST     /cities                 Cities      create          cities_create
    PUT      /cities                 Cities      update          cities_update
    DELETE   /cities                 Cities      delete          cities_delete


or written as code:


        # GET /cities/new - form to create a user
        $r->route('/cities/new')->via('get')
          ->to(controller => 'cities', action => 'new_form')
          ->name('cities_new_form');

        # GET /cities/123 - show user with id 123
        $r->route('/cities/:id')->via('get')
          ->to(controller => 'cities', action => 'show')->name('cities_show');

        # GET /cities/123/edit - form to update a user
        $r->route('/cities/:id/edit')->via('get')
          ->to(controller => 'cities', action => 'edit_form')
          ->name('cities_edit_form');

        # GET /cities - list of all cities
        $r->route('/cities')->via('get')
          ->to(controller => 'cities', action => 'index')
          ->name('cities_index');

        # POST /cities - create new user
        $r->route('/cities')->via('post')
          ->to(controller => 'cities', action => 'create')
          ->name('cities_create');

        # PUT /cities/123 - update an existing user
        $r->route('/cities/:id')->via('put')
          ->to(controller => 'cities', action => 'update')
          ->name('cities_update');

        # GET /cities/123/delete - form to confirm delete
        $r->route('/cities/:id/delete')->via('get')
          ->to(controller => 'cities', action => 'delete_form')
          ->name('cities_delete_form');

        # DELETE /cities/123 - delete an existing user
        $r->route('/cities/:id')->via('delete')
          ->to(controller => 'cities', action => 'delete')
          ->name('cities_delete');

Actually, L<Mojolicious::Plugin::ResourcefulRoutes> makes use of nested routes
(the code above defines seperate routes for demonstration purposes).

Sometimes, you don't want to give users access to all, but only selected
controller methods.

To allow users to just display information on a single city and to list all
cities, you can use the "only" option:

    $self->resources('cities', -only => ['show', 'index'])

To allow users to view, create and update cities, but not to delete a city, you
can use the "except" option:

    $self->resources('cities', -except => ['delete', 'delete_form'])


To dispatch to a more complex controller structure, you can use hyphens, e.g.
$self->resources('admin-cities') creates the following routes:

    HTTP     URL (not including            Contoller         Method          Route Name
    request  http://localhost:3000)
    method          

    GET      /admin/cities/new             Admin/Cities      new_form        admin-cities_new_form
    GET      /admin/cities/paris           Admin/Cities      show            admin-cities_show
    GET      /admin/cities/paris/edit      Admin/Cities      edit_form       admin-cities_edit_form
    GET      /admin/cities/paris/delete    Admin/Cities      delete_form     admin-cities_delete_form
    GET      /admin/cities                 Admin/Cities      index           admin-cities_index
    POST     /admin/cities                 Admin/Cities      create          admin-cities_create
    PUT      /admin/cities                 Admin/Cities      update          admin-cities_update
    DELETE   /admin/cities                 Admin/Cities      delete          admin-cities_delete


Sometimes, it makes sense to just define singular resources. For example, if
each user is responsible for managing the data of exactly one city, the user
data could be derived from a session cookie and the name of the city would than
be read from a database using the username. In that case, the name of the city
doesn't has to be part of the URL.

Use $self->resources('city', -singular => 1) in order to generate the following
routes:

    HTTP     URL (not including      Contoller   Method          Route Name
    request  http://localhost:3000)
    method          

    GET      /city/new               City         new_form        city_new_form
    GET      /city                   City         show            city_show
    GET      /city/edit              City         edit_form       city_edit_form
    GET      /city/delete            City         delete_form     city_delete_form
    POST     /city                   City         create          city_create
    PUT      /city                   City         update          city_update
    DELETE   /city                   City         delete          city_delete


=head1 METHODS

L<Mojolicious::Plugin::ResourcefulRoutes> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<resources>

    $self->resources('foo', 'bar', 'baz');

Add resources.

=head1 AUTHOR

ForwardEver

=head1 COPYRIGHT

Copyright (C) 2010, ForwardEver.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut



1;
