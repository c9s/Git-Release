package Git::Release::BranchManager;
use warnings;
use strict;
use Moose;

has manager => ( is => 'rw', isa => 'Git::Release' );

sub local_branches { 

}

sub remote_branches {
    my $self = shift;
    my @list = grep {  ! /HEAD/ } $self->manager->repo->command( 'branch' , '-r' );
    map { $_ =~ s/^\s*(\S+)\s*.*/\1/g } @list;
    chomp @list;
    
    # remove remtoes names, strip star char.
    return map { $self->manager->_new_branch( ref => $_ ) } @list;
}

1;
