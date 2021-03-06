#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 185;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;

my $t = Test::Mojo->new(app => 'Test');

use_ok 'Test';
use_ok 'Test::Users';
use_ok 'Test::Admin::Users';



### Test return values

# one resource defined
my $app = Test->new;
my $nested = $app->resources('cars');

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Cars" controller)
my $defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'cars';

# is plural (8 routes)
is @{$nested->children}, 8;



# same test with options
$app = Test->new;
$nested = $app->resources('cars', -only => ['index', 'show']);

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Cars" controller)
$defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'cars';

# -only limits child routes
is @{$nested->children}, 2;



# now multiple resources defined, only last route returned
$app = Test->new;
$nested = $app->resources('cars', 'members');

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Members" controller)
$defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'members';

# is plural (8 routes)
is @{$nested->children}, 8;



# same test with options
$app = Test->new;
$nested = $app->resources('cars', 'members', -only => ['index', 'show']);

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Members" controller)
$defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'members';

# -only limits child routes
is @{$nested->children}, 2;



# similar test for singular route
$app = Test->new;
$nested = $app->resources('cars', 'member', -singular => 1);

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Members" controller)
$defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'member';

# is singular (7 child routes)
is @{$nested->children}, 7;



# same test with options
$app = Test->new;
$nested = $app->resources('cars', 'member', -singular => 1, -only => ['index', 'show']);

# returns routes object
is ref $nested, 'Mojolicious::Routes';

# is nested routes object (parent of routes that dispatch to "Members" controller)
$defaults = $nested->children->[0]->pattern->defaults;
is $defaults->{controller}, 'member';

# -only limits child routes (index is ignored)
is @{$nested->children}, 1;




### Make real requests

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

$t->get_ok('/users/123/othermethod')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


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


$t->get_ok('/admin/users/123/othermethod')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


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




# /member (singular resource)

$t->get_ok('/member/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item! Route name: member_new_form");


$t->get_ok('/member')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item! Route name: member_show");


$t->get_ok('/member/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to edit an existing resource item! Route name: member_edit_form");


$t->get_ok('/member/delete')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to delete an existing resource item! Route name: member_delete_form");


$t->post_ok('/member')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("POST request, create method executed! Route name: member_create");


$t->put_ok('/member')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: member_update");


$t->post_form_ok('/member' => {_method => 'put'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("PUT request, update method executed! Route name: member_update");


$t->delete_ok('/member')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: member_delete");


$t->post_form_ok('/member' => {_method => 'delete'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: member_delete");


# /users/ "except" option

$t = Test::Mojo->new(app => 'Test2');

$t->get_ok('/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a list of resource items! Route name: users_index");


$t->get_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item! Route name: users_show");


$t->get_ok('/users/123/delete')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


$t->post_form_ok('/users/123' => {_method => 'delete'})
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');



$t->get_ok('/member/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to create a new resource item! Route name: member_new_form");


$t->get_ok('/member')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a single resource item! Route name: member_show");


$t->get_ok('/member/delete')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


$t->delete_ok('/member')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');



# /users/ "only" option

$t = Test::Mojo->new(app => 'Test3');

$t->get_ok('/users')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


$t->get_ok('/users/123')
  ->status_is(404)
  ->header_is(Server => 'Mojolicious (Perl)');


$t->get_ok('/users/123/delete')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("Template for displaying a form that allows to delete an existing resource item! Route name: users_delete_form");


$t->post_form_ok('/users/123' => {_method => 'delete'})
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_is("DELETE request, delete method executed! Route name: users_delete");



1;
