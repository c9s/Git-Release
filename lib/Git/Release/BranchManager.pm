package Git::Release::BranchManager;
use warnings;
use strict;
use Moose;

has manager => ( is => 'rw', isa => 'Git::Release' );


sub _parse_branches { 
    my $self = shift;
    my @list = grep { ! /HEAD/ } $self->manager->repo->command( 'branch' , '-a' );
    chomp @list;

    # strip spaces
    map { s{^\*?\s*}{}g } @list;
    return @list;
}

sub local_branches { 
    my $self = shift;
    my @list = grep !/^remotes/, $self->_parse_branches;
    return map { $self->manager->_new_branch( ref => $_ ) } @list;
}

sub remote_branches {
    my $self = shift;
    my @list = grep /^remotes/,$self->_parse_branches;

    # remove remtoes names, strip star char.
    return map { $self->manager->_new_branch( ref => $_ ) } @list;
}

sub find_local_branches {
    my ( $self, $name ) = @_;
    my @branches = $self->local_branches;
    if ( ref $name eq 'RegExp' ) {
        @branches = grep { $_->name =~ $name } @branches;
    } else {
        @branches = grep { $_->name eq $name } @branches;
    }
    return @branches if wantarray;
    return @branches[0];
}


1;
