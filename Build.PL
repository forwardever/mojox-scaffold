use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::ResourcefulRoutes',
	license             => 'perl',
	create_makefile_pl  => 'traditional',
	dist_author         => 'Andre Vieth (forwardever)',
	dist_version_from   => 'lib/Mojolicious/Plugin/ResourcefulRoutes.pm',
	dist_abstract       => 'resourceful routes for mojolicious',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Mojolicious' => '0.999929',
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'http://github.com/forwardever/mojolicious-plugin-resourceful_routes',
		},
		keywords => ['mojo', 'mojolicious', 'REST', 'route', 'routes', 'plugin', 'resource', 'resources'],
	},
);

$builder->create_build_script();

1;
