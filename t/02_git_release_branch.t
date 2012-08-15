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

done_testing;
