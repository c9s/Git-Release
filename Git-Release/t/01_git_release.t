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
ok( $re->config->repo , 'Repository object' );
is( 'Git' , ref( $re->config->repo ) , 'is Git');

my $branch = Git::Release::Branch->new( ref => 'test' , repo => $re->repo );
ok( $branch , 'branch ok' );

$branch->create( from => 'master' );
ok( $branch->is_local );

$branch->remove;


done_testing;
