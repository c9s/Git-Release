#!/usr/bin/env perl
use Test::More;
use lib qw'lib t/lib';
use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);
use GitTestUtils qw(create_repo mk_commit);


my $re = Git::Release->new;
ok $re;
ok $re->repo , 'get Git repo object';
ok $re->directory , 'get directory';
ok $re->branch , 'got branch manager';

# create_repo 'test_repo';
# mk_commit $re, 'README', 'root commit';

my @branches = $re->branch->remote_branches;
ok @branches;
for my $b ( @branches ) {
    is 'Git::Release::Branch', ref $b;
    ok $b->remote, $b->remote;
    ok $b->is_remote , 'is remote';
    like $b->remote, qr/origin|github/;
}

my @branches = $re->branch->local_branches;
ok @branches;
for my $b ( @branches ) {
    is 'Git::Release::Branch', ref $b;
    ok $b->is_local, 'is local';
}


diag "test local branch finder";
{
    my $local;
    $local = $re->branch->find_local_branches( 'master' );
    is ref($local),'Git::Release::Branch';

    ($local) = $re->branch->find_local_branches( 'master' );
    is ref($local),'Git::Release::Branch';
}

diag "test remote branch finder";
{
    my $b;
    $b = $re->branch->find_remote_branches( 'master' );
    is ref($b),'Git::Release::Branch';

    ($b) = $re->branch->find_remote_branches( 'master' );
    is ref($b),'Git::Release::Branch';
    ok $b->is_remote;
}


{
    my $current = $re->branch->current;
    ok $current;
    is ref($current),'Git::Release::Branch';
    ok $current->name;
    ok $current->ref;
}

{
    # create ready branch
    my $master = $re->branch->new_branch('master');
    my $develop = $re->branch->new_branch( 'develop' )->create( from => 'master' );
    ok $develop , 'develop branch is created';
    $develop->checkout;
    is $re->branch->current->name, 'develop';
    $master->checkout;
    is $re->branch->current->name, 'master';
    $develop->delete;
    ok $develop->is_deleted, 'is deleted';
}



done_testing;
