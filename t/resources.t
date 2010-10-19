#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 59;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;

my $t = Test::Mojo->new(app => 'Test');

use_ok 'Test';
use_ok 'Test::Users';
use_ok 'Test::Admin::Users';



# /users/

$t->get_ok('/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a list of resource items\n");


$t->get_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item\n");


$t->get_ok('/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to edit an existing resource item\n");


$t->get_ok('/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item\n");


$t->post_ok('/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("POST request, create method executed! Route name: users_create");


$t->put_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: users_update");


$t->delete_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: users_delete");



# /admin/users

$t->get_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a list of resource items\n");

$t->get_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item\n");


$t->get_ok('/admin/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to edit an existing resource item\n");

$t->get_ok('/admin/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item\n");


$t->post_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("POST request, create method executed! Route name: admin-users_create");


$t->put_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: admin-users_update");


$t->delete_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: admin-users_delete");


1;