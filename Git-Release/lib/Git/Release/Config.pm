package Git::Release::Config;
use warnings;
use strict;
use Mo;

has repo => ();

sub ready_prefix {
    my $self = shift;
    return $self->repo->config('release.ready-prefix') || 'ready-';
}







1;
