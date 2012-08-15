package Git::Release::BranchManager;
use warnings;
use strict;
use Moose;

has manager => ( is => 'rw', isa => 'Git::Release' );

1;
