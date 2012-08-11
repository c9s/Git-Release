package Git::Release::Branch;
use warnings;
use strict;
use Moose;
use File::Spec;
use File::Path qw(mkpath);

has name => ( is => 'rw' , isa => 'Str' );

has ref => ( is => 'rw' );

has manager => ( is => 'rw' );

has remote => ( is => 'rw' );

sub BUILD {
    my ($self,$args) = @_;
    unless( $args->{remote} ) {
        my $remote_name = $self->parse_remote_name($args->{ref});
        $self->remote($remote_name);
    }
    unless( $args->{name} ) {
        my $name = $self->strip_remote_prefix( $args->{ref} );
        $self->name($name);
    }
    return $args;
}


=head2 parse_remote_name

Parse remote name from ref, like:

    remotes/origin/branch_name

=cut

sub parse_remote_name {
    my ($self,$ref) = @_;
    my $new = $ref;
    my ($remote) = ($new =~ m{^remotes\/([^/]+?)\/});
    return $remote;
}


=head2 strip_remote_prefix

Strip remotes prefix from branch ref string

    remotes/origin/branch_name

To

    origin/branch_name

=cut

sub strip_remote_prefix {
    my ($self,$ref) = @_;
    my $new = $ref;
    $new =~ s{^remotes\/([^/]+?)\/}{};
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

sub rebase_from {
    my ($self,$from) = @_;
    if( ! ref($from) ) {
        $from = $self->manager->_new_branch( ref => $from );
    }
    my @ret = $self->manager->repo->command( 'rebase' , $from->name , $self->name );
    return @ret;
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
        $self->manager->repo->command( 'branch' , '-m' , $name , $new_name );
        $self->ref( $new_name );
        $self->push_to_remotes;
        return $new_name;
    }
    elsif( $self->is_remote ) {
        my $name = $self->name;

        # branch from remote ref
        my $origin_branch_name = $self->ref;
        my $ready_branch_name = 'ready/' . $self->name;
        $self->manager->repo->command( 'branch' , $ready_branch_name , $self->ref );
        $self->manager->repo->command( 'push'   , 'origin' , $ready_branch_name );
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

        $self->remove_remote_branches;

        $self->manager->repo->command( 'branch' , '-m' , $name 
                , $new_name );
        $self->ref( $new_name );
        $self->push_to_remotes;
        return $new_name;
    }
}

sub get_doc_path {
    my $self = shift;
    my $docname = $self->name;
    return if $self->name eq 'HEAD';

    $docname =~ s/^@{[ $self->manager->config->released_prefix ]}//;
    $docname =~ s/^@{[ $self->manager->config->ready_prefix ]}//;

    my $ext = $self->manager->config->branch_doc_ext;

    my $dir = File::Spec->join( $self->manager->repo->wc_path , $self->manager->config->branch_doc_path );
    mkpath [ $dir ] if ! -e $dir ;
    return File::Spec->join( $dir , "$docname.$ext" );
}

sub default_doc_template {
    my $self = shift;
    return <<"END";
@{[ $self->name ]}
======

REQUIREMENT
------------

SYNOPSIS
------------

PLAN
------------

KNOWN ISSUES
------------

END
}

sub init_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;


    print "Initializing branch documentation.\n";
    open my $fh , ">" , $doc_path;
    print $fh $self->default_doc_template;
    close $fh;

    $self->edit_doc;
    print "Done.\n";
}

sub edit_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;

    # XXX:
    # launch editor to edit doc
#     my $bin = $ENV{EDITOR} || 'vim';
#     system(qq{$bin $doc_path}) == 0
#         or die "System failed: $?";

}

sub print_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;

    print "Branch doc path: $doc_path\n";

    # doc doesn't exists
    unless(-e $doc_path ){
        print "Branch doc $doc_path not found.\n";
        $self->init_doc;
        return;
    }

    if($doc_path =~ /\.pod$/) {
        system("pod2text $doc_path");
    }
    else {
        open my $fh , "<" , $doc_path;
        local $/;
        my $content = <$fh>;
        close $fh;
        print "===================\n";
        print $content , "\n";
        print "===================\n";
    }
}



1;
__END__

=head2 Status Changing methods

=head3 remove_remote_branches

=head3 move_to_ready 

=head3 move_to_released

=cut
