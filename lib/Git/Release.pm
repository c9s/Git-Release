package Git::Release;
use strict;
use warnings;
our $VERSION = '0.01';
use feature qw(say switch);
use Mo;
use Cwd;
use Git;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use DateTime;
use Git::Release::Config;
use Git::Release::Branch;

has directory => ( );

has repo => (  );

has config => ( );

sub new {
    my ($class,%args) = @_;
    my $self = bless {} ,$class;
    my $dir = $args{directory} || getcwd();

    my $repo = Git->repository( Directory => $dir );
    $self->repo( $repo );
    $self->directory( $dir );
    $self->config( Git::Release::Config->new( repo => $repo )  );
    return $self;
}

sub strip_remote_names { 
    my $self = shift; 
    map { s{^remotes\/.*?\/}{}; $_ } @_;
}

# list all remote, all local branches
sub list_all_branches {
    my $self = shift;

    # remove remtoes names, strip star char.
    return uniq 
            map { chomp; $_; } 
            map { s/^\*?\s*//; $_; } 
                $self->repo->command( 'branch' , '-a' );
}

sub list_remote_branches {
    my $self = shift;
    return map { chomp; $_; } 
           map { s/^\*?\s*//; $_; } 
           $self->repo->command( 'branch' , '-r' );
}

sub list_local_branches {
    my $self = shift;
    return map { chomp; $_; } 
           map { s/^\*?\s*//; $_; } 
           $self->repo->command( 'branch' , '-l' );
}

sub get_current_branch {
    my $self = shift;
    my $result = $self->repo->command('rev-parse','--abbrev-ref','HEAD');
    chomp( $result );
    return $self->_new_branch( ref => $result );
}


# return branches with ready prefix.
sub get_ready_branches {
    my $self = shift;
    my $prefix = $self->config->ready_prefix;
    my @branches = $self->list_all_branches;
    my @ready_branches = grep /$prefix/, @branches;
    return map { $self->_new_branch( ref => $_ ) } @ready_branches;
}

sub get_release_branches {
    my $self = shift;
    my $prefix = $self->config->release_prefix;
    my @branches = $self->list_all_branches;
    my @release_branches = sort grep /$prefix/, @branches;
    return map { $self->_new_branch( ref => $_ ) } @release_branches;  # release branch not found.
}

sub get_remotes {
    my $self = shift;
    my @remotes = split /\n/,$self->repo->command('remote');
    return @remotes;
}

sub update_remote_refs {
    my $self = shift; 
    $self->repo->command(qw(remote update --prune));
    $self->repo->command(qw(fetch --all --prune));
}

sub _new_branch {
    my ( $self, %args ) = @_;
    my $branch = Git::Release::Branch->new(  
            %args, manager => $self );
    return $branch;
}




sub checkout_release_branch {
    my $self = shift;
    my @rbs = $self->get_release_branches;
    my ($rb) = grep { $_->is_local } @rbs;
    unless( $rb ) {
        ($rb) = grep { $_->is_remote } @rbs;
    }

    unless ($rb) {
        die 'Release branch not found.';
    }

    $rb->checkout;
    return $rb;
}


sub has_develop_branch {
    my $self = shift;
    my $dev_branch_name = $self->config->develop_branch;
    my @branches = $self->list_all_branches;
    for my $branch ( @branches ) {
        my $branch = $self->_new_branch( ref => $branch );
        return $branch if $branch->name eq $dev_branch_name;
    }
    return undef;
}

sub create_develop_branch {
    my $self = shift;
    my $name = $self->config->develop_branch;
    my $branch = $self->_new_branch( ref => $name );
    $branch->create( from => 'master' );
    return $branch;
}

sub create_feature_branch {
    my ($self,$bname,$ref) = @_;
    my $prefix = $self->config->feature_prefix;
    my $b = $self->_new_branch( ref => $prefix . $bname );
    $b->create( from => $ref || $self->config->develop_branch );
    return $b;
}

1;
__END__

=head1 NAME

Git::Release -

=head1 SYNOPSIS

  use Git::Release;

=head1 DESCRIPTION

Git::Release is a release manager for Git. It includes the basic concepts of git workflow.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
