#!/usr/bin/env perl

# Copyright (C) 2010, ForwardEver

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'MojoX::Scaffold',
    VERSION_FROM => 'lib/Mojolicious/Plugin/ResourcefulRoutes.pm',
    ABSTRACT     => 'Build RESTful resources with Mojolicious',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'https://github.com/forwardever/mojox-scaffold'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {'Mojolicious' => '0.999931'},
    test      => {TESTS         => 't/*.t'}
);

1;
