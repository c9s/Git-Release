#!/usr/bin/env perl
use Test::More;
use lib 'lib';

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;

my $re = Git::Release->new;

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

ok( $re->config );
ok( $re->config->repo );
is( 'Git' , ref( $re->config->repo ));

my $branch = Git::Release::Branch->new( ref => 'master' );


done_testing;
