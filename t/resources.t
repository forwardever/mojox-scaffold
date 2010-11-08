#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 83;

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
  ->content_is("Template for displaying a list of resource items! Route name: users_index");


$t->get_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item! Route name: users_show");


$t->get_ok('/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to edit an existing resource item! Route name: users_edit_form");

$t->get_ok('/users/123/delete')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to delete an existing resource item! Route name: users_delete_form");


$t->get_ok('/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item! Route name: users_new_form");


$t->post_ok('/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("POST request, create method executed! Route name: users_create");


$t->put_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: users_update");


$t->post_form_ok('/users/123' => {_method => 'put'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: users_update");


$t->delete_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: users_delete");


$t->post_form_ok('/users/123' => {_method => 'delete'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: users_delete");



# /admin/users

$t->get_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a list of resource items! Route name: admin-users_index");


$t->get_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item! Route name: admin-users_show");


$t->get_ok('/admin/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to edit an existing resource item! Route name: admin-users_edit_form");

$t->get_ok('/admin/users/123/delete')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to delete an existing resource item! Route name: admin-users_delete_form");


$t->get_ok('/admin/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item! Route name: admin-users_new_form");


$t->post_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("POST request, create method executed! Route name: admin-users_create");


$t->put_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: admin-users_update");


$t->post_form_ok('/admin/users/123' => {_method => 'put'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: admin-users_update");


$t->delete_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: admin-users_delete");


$t->post_form_ok('/admin/users/123' => {_method => 'delete'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: admin-users_delete");



1;
