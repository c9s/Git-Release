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

sub remove {
    my ($self,%args) = @_;
    if( $self->is_local ) {
        $self->manager->repo->command( 'branch' , '-d' , $self->ref );
    } elsif( $self->is_remote ) {
        $self->manager->repo->command( 'push' , $self->remote_name , ':' . $self->name );
    }
}


# if self is a local branch, we can check if it has a remote branch
sub remove_remote_branches {
    my $self = shift;
    my @remotes = split /\n/,$self->manager->repo->command( 'remote' );
    for ( @remotes ) {
        $self->manager->repo->command( 'push' , $_ , '--delete' , $self->name );
    }
}

sub move_to_ready {
    my $self = shift;
    if( $self->is_local ) {
        my $name = $self->name;
        return if $name =~ $self->manager->config->ready_prefix;
        my $new_name = $self->manager->config->ready_prefix . $name;
        $self->manager->repo->command( 'branch' , '-m' , $name , $new_name );
        $self->ref( $new_name );
        return $new_name;
    }
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

1;
