package Git::Release;
use warnings;
use strict;
use Cwd;

sub new { 
    my $self = {};
    bless $self , shift;

    my $working_dir = getcwd();
    my $repo = Git->repository ( WorkingSubdir => $working_dir );
    $self->{repo} = $repo;
    return $self;
}


1;
