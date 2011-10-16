#!/usr/bin/env perl
use Test::More;
use lib 'lib';

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree);

mkdir 'test_repo' unless -e 'test_repo';
chdir 'test_repo';

my $re = Git::Release->new;
$re->repo->command( 'init' );

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

ok( $re->config );
ok( $re->config->repo , 'Repository object' );
is( 'Git' , ref( $re->config->repo ) , 'is Git');

{
    my $branch = Git::Release::Branch->new( ref => 'test', manager => $re );
    ok( $branch , 'branch ok' );

    is( $branch->name , 'test' , 'branch name' );

    $branch->create( from => 'master' );
    ok( $branch->is_local );

    my $new_name = $branch->move_to_ready;
    ok( $new_name , $new_name );
    $branch->remove;
}




{
    my $branch = Git::Release::Branch->new( ref => 'test', manager => $re );
    ok( $branch , 'branch ok' );

    is( $branch->name , 'test' , 'branch name' );

    $branch->create( from => 'master' );
    ok( $branch->is_local );

    my $new_name = $branch->move_to_ready;
    ok( $new_name , $new_name );
    $branch->remove;
}


chdir '..';
rmtree [ 'test_repo' ];

done_testing;
