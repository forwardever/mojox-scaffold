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
  ->content_like(qr/Template for displaying a list of resource items/);


$t->get_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a single resource item/);


$t->get_ok('/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a form that allows to edit an existing resource item/);


$t->get_ok('/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a form that allows to create a new resource item/);


$t->post_ok('/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/POST request, create method executed!/);


$t->put_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/PUT request, update method executed!/);


$t->delete_ok('/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/DELETE request, delete method executed!/);



# /admin/users

$t->get_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a list of resource items/);

$t->get_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a single resource item/);


$t->get_ok('/admin/users/123/edit')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a form that allows to edit an existing resource item/);

$t->get_ok('/admin/users/new')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/Template for displaying a form that allows to create a new resource item/);


$t->post_ok('/admin/users')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/POST request, create method executed!/);


$t->put_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/PUT request, update method executed!/);


$t->delete_ok('/admin/users/123')
  ->status_is(200)
  ->header_is(Server => 'Mojolicious (Perl)')
  ->content_like(qr/DELETE request, delete method executed!/);



1;
