package Git::Release::Branch;
use warnings;
use strict;
use Mo;

has ref => ();

has manager => ();

sub name {
    my $self = shift;
    if( $self->is_remote ) {
        my $ref = $self->strip_remote_prefix( $self->ref );
        return $ref;
    }
    else {
        return $self->ref;
    }
}

sub strip_remote_prefix {
    my ($self,$ref) = @_;
    my $new = $ref;
    $new =~ s{^remotes\/.*?\/}{};
    return $new;
}

sub is_local {
    my $self = shift;
    return ! $self->is_remote;
}

sub is_remote {
    my $self = shift;
    return $self->ref =~ m{^remotes/};
}

sub remote_name {  
    my $self = shift;
    if($self->is_remote) {
        my ($name) = ($self->ref =~ m{^remotes/(.*?)/});
        return $name;
    }
}




sub create {
    my ($self,%args) = @_;
    my $from = $args{from} || 'master';
    $self->manager->repo->command( 'branch' , $self->ref , 'master' );
}


# options:
#
#    ->remove( force => 1 );
sub remove {
    my ($self,%args) = @_;
    if( $self->is_local ) {
        $self->manager->repo->command( 'branch' , $args{force} ? '-D' : '-d' , $self->ref );
    } elsif( $self->is_remote ) {
        $self->manager->repo->command( 'push' , $self->remote_name , ':' . $self->name );
    }
}


# Remove remote tracking branches
# if self is a local branch, we can check if it has a remote branch
sub remove_remote_branches {
    my $self = shift;
    my $name = $self->name;
    my @remotes = $self->manager->repo->command( 'remote' );
    my @rbs = $self->manager->list_remote_branches;

    for my $remote ( @remotes ) {
        # has tracking branch at remote ?
        if( grep m{$remote/$name},@rbs ) {
            $self->manager->repo->command( 'push' , $remote , '--delete' , $self->name );
        }
    }
}


sub move_to_ready {
    my $self = shift;

    if( $self->is_local ) {
        my $name = $self->name;
        return if $name =~ $self->manager->config->ready_prefix;

        $self->remove_remote_branches;

        my $new_name = $self->manager->config->ready_prefix . $name;
        $self->manager->repo->command( 'branch' , '-m' , $new_name );
        $self->ref( $new_name );
        $self->push_to_remotes;
        return $new_name;
    }
}

sub checkout {
    my $self = shift;
    my @ret;
    if( $self->is_local ) {
        @ret = $self->manager->repo->command( 'checkout' , $self->name );
    } else {
        # checkout a remote tracking branch
        @ret = $self->manager->repo->command( 'checkout' , '-b' , '-t' , $self->name , $self->ref );
    }
    return @ret;
}

sub merge {
    my ($self,$b) = @_;
    my @ret = $self->manager->repo->command( 'merge' , $b->ref );
    return @ret;
}

sub move_to_released {
    my $self = shift;
    my $name = $self->name;
    my $released_prefix = $self->manager->config->released_prefix;
    return if $name =~ $released_prefix;

    if( $self->is_local ) {
        my $new_name = $name;
        $new_name =~ s{^.*/}{};
        $new_name = $released_prefix . $new_name;
        $self->manager->repo->command( 'branch' , '-m' , $name 
                , $new_name );
        $self->ref( $new_name );
        return $new_name;
    }
}

sub push_to {
    my ($self,$remote) = @_;
    $self->manager->repo->command( 'push' , $remote , $self->name );
}

sub push_to_remotes {
    my $self = shift;
    my @remotes = $self->manager->get_remotes;
    $self->push_to($_) for @remotes;
}

1;
