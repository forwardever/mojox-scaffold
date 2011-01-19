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

            my $last_route;

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

                $last_route = $self->generate_routes($c, $resource, $options);

            }

            return $last_route;

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


    # Nested route
    my $nr = $r->route("$path");


    # Singular resource, i.e. app knows id value (e.g. from login)
    if ($singular) {

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

    return $nr;

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


=head1 THE ADVANTAGE OF ROUTES

Instead of letting a web server like Apache decide which files to serve based on
the provided URL, the whole work can be done by a Mojolicious application.

For example, a URL like

    http://www.example.com/cities/paris.html

can provide content that has been retrieved from a database, or also content
that has been fetched from another website in "real-time", or even continuously
updating content retrieved from other users sitting in front of their computers.

So, Mojolicious allows you to display dynamic content in a search engine
friendly way!

In order to achieve this, Mojolicious decides on it's own how to handle URLs and
what to deliver as a result.

This is where routes come into play. Routes are kind of "rules" how to handle
URLs. Mojolicious checks whether a specific URL matches a certain pattern (as
defined in the route), and determines what happens if a match occurs (as also
defined in the route).

For example, you can configure Apache to handle all URLs, except requests for
http://yourdomain.com/myapp, so that URLs like

    http://yourdomain.com/myapp/users.html
    http://yourdomain.com/myapp/data.html

are handled by Mojolicious.

Routes themselves are very dynamic (think of them as kind of simplified regular
expressions), so another advantage of routes is that an infinite amount of URLs
can be handled, without the need to place a file for each URL on your server .

For example, the following route (using a placeholder)

    /:cities/

would be responsible to deliver content for the following URLs:

    http://yourdomain.com/myapp/new_york.html
    http://yourdomain.com/myapp/paris.html or
    http://yourdomain.com/myapp/any_other_city.html

Finally, routes are reversible. Instead of hard copying URLs in your templates,
you can use route names in templates, forms and redirects. If you decide to
relocate the content (provide content under a different URL), you just need to
modifiy the route, not the templates, forms etc.

Creating routes is not that difficult, but requires a lot of typing. In addition
to that, the route structures for many tasks are very similar, they just have
to provide some kind of CRUD (create, read, update, delete) functionality.

For example, in order to manage a list of cities, you need routes to
    - list all cities,
    - display information on a single city,
    - display forms to create, update and delete cities
    - and to finally create, update and delete cities.

In order to manage a list of users, you need very similar routes. Why
reinventing the wheel again and again if route structures are very
similar in many cases.

This is where L<Mojolicious::Plugin::ResourcefulRoutes> comes into play. It
allows you to define a bunch of routes with a single command.


=head1 DESCRIPTION

While there are many ways to make use of routes, one frequent use case is to
dispatch user requests to a specific controller method based on the HTTP request
method (GET, POST, PUT, DELETE) and the request path (e.g. /cities/new).

These controller methods than allow the user to create, read, update and delete
data stored in a database. L<Mojolicious::Plugin::ResourcefulRoutes> automates
the process of routes creation for CRUD functionality (it does not provide the
CRUD functionality itself, just the routes!).

$self->resources('cities') automatically generates the following
routes on each start of your app.

    HTTP     URL (not including      Contoller   Method          Route Name
    request  http://localhost:3000)
    method          

    GET      /cities/new             Cities      new_form        cities_new_form
    GET      /cities/:id             Cities      show            cities_show
    GET      /cities/:id/edit        Cities      edit_form       cities_edit_form
    GET      /cities/:id/delete      Cities      delete_form     cities_delete_form
    GET      /cities                 Cities      index           cities_index
    POST     /cities                 Cities      create          cities_create
    PUT      /cities/:id             Cities      update          cities_update
    DELETE   /cities/:id             Cities      delete          cities_delete

For example, if a user requests "/cities/paris/edit" via "GET", the "edit_form"
method of the "Cities" controller is called. It's up to you what to put into
this controller method, but usually it would be responsible to display
a HTML form allowing you to edit a single city (in this case "paris").

As the routes generated by $self->resources('cities') make use of a placeholder
(:id), the actual name of the city is saved in the so called stash. As a result,
the name of the city can easily be accessed in the controller method:

    my $name = $self->stash('id') # $self is a controller object

The code generated in the background looks more like this (however, 
L<Mojolicious::Plugin::ResourcefulRoutes> makes use of nested routes, while the
following code defines seperate routes for demonstration purposes):


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
