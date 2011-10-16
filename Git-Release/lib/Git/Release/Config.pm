package Git::Release::Config;
use warnings;
use strict;
use Mo;

has repo => ();

sub ready_prefix {
    my $self = shift;
    return $self->repo->config('release.ready-prefix') || 'ready-';
}

sub release_prefix {
    my $self = shift;
    return $self->repo->config('release.release-prefix') || 'release-'; 
}

sub develop_branch {
    my $self = shift;
    return $self->repo->config('release.develop-branch') || 'develop';
}







1;
