package Mojolicious::Plugin::ResourcefulRoutes;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream;

our $VERSION = '0.03';

sub register {
    my ($self, $app) = @_;

    $app->plugins->add_hook(
        before_dispatch => sub {
            my ($self, $c) = @_;

            if ($c->req->method eq 'POST') {
                if (lc($c->req->param('_method')) eq 'delete') {
                    $c->req->method('DELETE');
                }
                elsif (lc($c->req->param('_method')) eq 'put') {
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

        # GET /article/new - form for create an article
        $r->route("/$path/new")->via('get')
          ->to(controller => $ctrl, action => "create_form")
          ->name($name . "_create_form");

        # GET /article - show article
        $r->route("/$path")->via('get')
          ->to(controller => $ctrl, action => "show")->name($name . "_show");

        # GET /article/edit - form for update an article
        $r->route("/$path/edit")->via('get')
          ->to(controller => $ctrl, action => "update_form")
          ->name($name . "_update_form");

        # POST /article - create article
        $r->route("/$path")->via('post')
          ->to(controller => $ctrl, action => "create")
          ->name($name . '_create');

        # PUT /article - update article
        $r->route("/$path")->via('put')
          ->to(controller => $ctrl, action => "update")
          ->name($name . '_update');

        # DELETE /article - delete article
        $r->route("/$path")->via('delete')
          ->to(controller => $ctrl, action => "delete")
          ->name($name . '_delete');
    }

    # Id passed via URL
    else {

        # GET /articles/new - form for create an article
        $r->route("/$path/new")->via('get')
          ->to(controller => $ctrl, action => "create_form")
          ->name($name . "_create_form");

        # GET /articles/123 - show article with id 123
        $r->route("/$path/:id")->via('get')
          ->to(controller => $ctrl, action => "show")->name($name . "_show");

        # GET /articles/123/edit - form for update an article
        $r->route("/$path/:id/edit")->via('get')
          ->to(controller => $ctrl, action => "update_form")
          ->name($name . "_update_form");

        # GET /articles - list of all articles
        $r->route("/$path")->via('get')
          ->to(controller => $ctrl, action => "index")
          ->name($name . '_index');

        # POST /articles - create new article
        $r->route("/$path")->via('post')
          ->to(controller => $ctrl, action => "create")
          ->name($name . '_create');

        # PUT /articles/123 - update article
        $r->route("/$path/:id")->via('put')
          ->to(controller => $ctrl, action => "update")
          ->name($name . '_update');

        # DELETE /articles/123 - delete article
        $r->route("/$path/:id")->via('delete')
          ->to(controller => $ctrl, action => "delete")
          ->name($name . '_delete');
    }
}

1;
