package GitTestUtils;
use warnings;
use strict;
use base qw(Exporter);


our @EXPORT_OK = qw(create_repo);

use Git::Release;
use Git::Release::Config;
use Git::Release::Branch;
use File::Path qw(rmtree mkpath);

sub create_repo {
    my $path = shift;;
    rmtree [ $path ] if -e $path;
    mkpath [ $path ] if ! -e $path;
    chdir $path;
    Git::command('init');
    return $path;
}

1;
