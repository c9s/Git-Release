#!/usr/bin/env perl
use Test::More;
use lib 'lib';

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree);

rmtree [ 'test_repo' ] if -e 'test_repo';
mkdir 'test_repo';
chdir 'test_repo';

Git::command('init');

my $re = Git::Release->new;
diag 'Testing Path: ' . $re->repo->wc_path;



sub make_change {
    my $re = shift;
    open FH , ">>" , 'README';
    print FH "README";
    close FH;
    $re->repo->command( 'add' , 'README' );
    $re->repo->command( 'commit' , 'README' , '-m' , '"Change"' );
}
make_change $re;


ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

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
    ok( $branch->is_local );

    my $new_name = $branch->move_to_ready;
    is( 'ready/test' , $new_name );

    $new_name = $branch->move_to_released;
    is( 'released/test' , $new_name );

    $branch->remove;
}

$re->gc;


chdir '..';
rmtree [ 'test_repo' ];

done_testing;
