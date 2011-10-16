package Git::Release::Branch;
use warnings;
use strict;
use Mo;

has ref => ();

has repo => ();

sub move_to_ready {
    my $self = shift;
}

sub move_to_release {
    my $self = shift;

}

sub name {
    my $self = shift;
    my ($name) = ( $self->ref =~ /\/(.*?)$/ );
    return $name;
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
    $self->repo->command( 'branch' , $self->ref , 'master' );
}

sub remove {
    my ($self,%args) = @_;
    if( $self->is_local ) {
        $self->repo->command( 'branch' , '-d' , $self->ref );
    } elsif( $self->is_remote ) {
        $self->repo->command( 'push' , $self->remote_name , ':' . $self->name );
    }
}


1;
