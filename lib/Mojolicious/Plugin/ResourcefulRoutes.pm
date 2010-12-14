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

            while (@params) {
                my $resource = shift(@params);
                my $options  = shift(@params)
                  if @params && ref $params[0] eq 'HASH';
                $options ||= {};
                $self->generate_routes($c, $resource, $options);
            }
        }
    );
}

sub generate_routes {
    my $self = shift;
    my ($c, $resource, $options) = @_;

    my $singular   = $options->{singular};


    # Create path for routes
    my $path = join('/', split(/-/, $resource) );


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
          ->name($name . '_new_form');

        # GET /article - show article
        $nr->route('/')->via('get')
          ->to(controller => $ctrl, action => 'show')->name($name . '_show');

        # GET /article/edit - form for update an article
        $nr->route('/edit')->via('get')
          ->to(controller => $ctrl, action => 'edit_form')
          ->name($name . '_edit_form');

        # GET /article/delete - form to confirm delete
        $nr->route('/delete')->via('get')
          ->to(controller => $ctrl, action => 'delete_form')
          ->name($name . '_delete_form');

        # POST /article - create article
        $nr->route('/')->via('post')
          ->to(controller => $ctrl, action => 'create')
          ->name($name . '_create');

        # PUT /article - update article
        $nr->route('/')->via('put')
          ->to(controller => $ctrl, action => 'update')
          ->name($name . '_update');

        # DELETE /article - delete article
        $nr->route('/')->via('delete')
          ->to(controller => $ctrl, action => 'delete')
          ->name($name . '_delete');
        
    }

    # Id passed via URL
    else {
        
        my $nr = $r->route("$path");

        # GET /articles/new - form for create an article
        $nr->route('/new')->via('get')
          ->to(controller => $ctrl, action => 'new_form')
          ->name($name . '_new_form');

        # GET /articles/123 - show article with id 123
        $nr->route('/:id')->via('get')
          ->to(controller => $ctrl, action => 'show')->name($name . '_show');

        # GET /articles/123/delete - form to confirm delete
        $nr->route('/:id/delete')->via('get')
          ->to(controller => $ctrl, action => 'delete_form')
          ->name($name . '_delete_form');

        # GET /articles/123/edit - form for update an article
        $nr->route('/:id/edit')->via('get')
          ->to(controller => $ctrl, action => 'edit_form')
          ->name($name . '_edit_form');

        # GET /articles - list of all articles
        $nr->route('/')->via('get')
          ->to(controller => $ctrl, action => 'index')
          ->name($name . '_index');

        # POST /articles - create new article
        $nr->route('/')->via('post')
          ->to(controller => $ctrl, action => 'create')
          ->name($name . '_create');

        # PUT /articles/123 - update article
        $nr->route('/:id')->via('put')
          ->to(controller => $ctrl, action => 'update')
          ->name($name . '_update');

        # DELETE /articles/123 - delete article
        $nr->route('/:id')->via('delete')
          ->to(controller => $ctrl, action => 'delete')
          ->name($name . '_delete');
    }
}

1;
