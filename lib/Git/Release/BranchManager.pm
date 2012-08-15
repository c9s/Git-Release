package Git::Release::BranchManager;
use warnings;
use strict;
use Moose;

has manager => ( is => 'rw', isa => 'Git::Release' );

sub local_branches { 

}

sub remote_branches {
    my $self = shift;
    my @list = $self->manager->repo->command( 'branch' , '-r' );

    # remove remtoes names, strip star char.
    return map { $self->manager->_new_branch( ref => $_ ) } map { chomp } @list;
}

1;
