#!/usr/bin/env perl
use Test::More;
use lib qw'lib t/lib';
use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);
use GitTestUtils qw(create_repo mk_commit);

create_repo 'test_repo';

my $re = Git::Release->new;
ok $re;
diag 'Testing Path: ' . $re->repo->wc_path;

mk_commit $re, 'README', 'new changes';

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

ok $re->branch , 'got branch manager';

ok( $re->get_current_branch );
is( 'master', $re->get_current_branch->name );
ok( 'master', $re->get_current_branch->ref );

ok( $re->config );
ok( $re->config->repo , 'Repository object' );
is( 'Git' , ref( $re->config->repo ) , 'is Git');


ok( ! $re->find_develop_branch , 'no dev branch' );
my $dev_branch;
ok( $dev_branch = $re->checkout_develop_branch );
ok( $re->find_develop_branch , 'found dev branch' );

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
    ok( $branch->is_local , 'branch created' );

    my $new_name = $branch->move_to_ready;
    is( 'ready/test' , $new_name , 'ready branch ok' );

    $new_name = $branch->move_to_released;
    is( 'released/test' , $new_name , 'released branch ok' );

    $branch->remove;
}

$re->gc;


chdir '..';
rmtree [ 'test_repo' ];

done_testing;
