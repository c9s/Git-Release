#!/usr/bin/env perl
use Test::More;
use lib 'lib';

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree);
