package Git::Release::Config;
use warnings;
use strict;
use Mo;

has repo => ();

sub ready_prefix {
    my $self = shift;
    return $self->repo->config('release.ready-prefix') || 'ready/';
}

sub released_prefix {
    my $self = shift;
    return $self->repo->config('release.released-prefix') || 'released/';
}

sub release_prefix {
    my $self = shift;
    return $self->repo->config('release.release-prefix') || 'release-'; 
}

sub feature_prefix {
    my $self = shift;
    return $self->repo->config('release.release-prefix') || 'feature-'; 
}

sub develop_branch {
    my $self = shift;
    return $self->repo->config('release.develop-branch') || 'develop';
}

1;
