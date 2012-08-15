package Git::Release;
use strict;
use warnings;
our $VERSION = '0.01';
use feature qw(say switch);
use Moose;
use Cwd;
use Git;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use DateTime;
use File::Spec;
use Git::Release::Config;
use Git::Release::Branch;
use Git::Release::BranchManager;

has directory => ( is => 'rw' , default => sub {  getcwd() } );

has repo => ( 
    is => 'rw',
    default => sub { 
        my $self = shift;
        return Git->repository( Directory => $self->directory );
    }
);

has config => ( is => 'rw' );

has branch => ( 
    is => 'rw', 
    isa => 'Git::Release::BranchManager',
    default => sub { 
        my $self = shift;
        return Git::Release::BranchManager->new( manager => $self );
    });

sub BUILD {
    my ($self,$args) = @_;
    $self->directory( $args->{directory} ) if $args->{directory};
    $self->config( Git::Release::Config->new( repo => $self->repo )  );
    return $self;
}

sub strip_remote_names { 
    my $self = shift; 
    map { s{^remotes\/.*?\/}{}; $_ } @_;
}

# list all remote, all local branches
# contains 
#    local-branch
#    remotes/origin/branch_name

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

sub get_current_branch_name { 
    my $self = shift;
    my $name = $self->repo->command('rev-parse','--abbrev-ref','HEAD');
    chomp( $name );
    return $name;
}

sub get_current_branch {
    my $self = shift;
    my $name = $self->get_current_branch_name;
    return $self->_new_branch( ref => $name );
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

sub install_hooks {
    my $self = shift;
    my $repo_path = $self->repo->repo_path;

    my $checkout_hook = File::Spec->join( $repo_path , 'hooks' , 'post-checkout' );
    print "$checkout_hook\n";
    open my $fh , ">" , $checkout_hook;

    print $fh <<"END";
#!/usr/bin/env perl
use Git::Release;
my \$m = Git::Release->new; # release manager
\$m->get_current_branch->print_doc;
END

    close $fh;
    chmod 0755, $checkout_hook;
}

sub get_remotes {
    my $self = shift;

    # provide a list context to get remote names
    my @remotes = $self->repo->command('remote');
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
    unless ($rb) {
        ($rb) = grep { $_->is_remote } @rbs;
    }

    unless ($rb) {
        die 'Release branch not found.';
    }

    $rb->checkout;
    return $rb;
}


=head2 find_branch

Find a specific branch from the branch list (remote and local).

=cut

sub find_branch {
    my ( $self, $name ) = @_;
    my @branches = $self->list_all_branches;
    for my $ref ( @branches ) {
        my $branch = $self->_new_branch( ref => $ref );
        return $branch if $branch->name eq $name;
    }
}

sub find_develop_branch {
    my $self = shift;
    my $dev_branch_name = $self->config->develop_branch;
    return $self->find_branch( $dev_branch_name );
}

# checkout or create develop branch
sub checkout_develop_branch {
    my $self = shift;
    my $name = $self->config->develop_branch;

    my $branch;
    $branch = $self->find_branch( $name );

    # if branch found, we should check it out
    if ( $branch ) {
        $branch->checkout;
    } else {
        $branch = $self->_new_branch( ref => $name );
        $branch->create( from => 'master' );
    }
    return $branch;
}

sub create_feature_branch {
    my ($self,$bname,$ref) = @_;
    my $prefix = $self->config->feature_prefix;
    my $b = $self->_new_branch( ref => $prefix . $bname );
    $b->create( from => $ref || $self->config->develop_branch );
    return $b;
}

sub gc {
    my $self = shift;
    my %args = @_;
    $self->repo->command( 'gc' , 
        $args{aggressive} ? '--aggressive' : () , 
        $args{prune} ? '--prune=' . ($args{prune} || 'now') : () );
}

1;
__END__

=head1 NAME

Git::Release - Release Process Manager

=head1 SYNOPSIS

    use Git::Release;

    my $manager = Git::Release->new;
    my @branches = $manager->branch->ready_branches;
    my @branches = $manager->branch->site_branches;
    my @branches = $manager->branch->feature_branches;
    my @branches = $manager->branch->hotfix_branches;
    my @branches = $manager->branch->find_branches( prefix => 'hotfix' );
    my @branches = $manager->branch->find_branch( name => 'feature/test' );
    my $current_branch = $manager->branch->current;

    my $prefix = $manager->get_ready_prefix;   # ready/
    my $prefix = $manager->get_site_prefix;    # site/
    my $prefix = $manager->get_hotfix_prefix;  # hotfix/

=head1 DESCRIPTION

Git::Release is a release manager for Git. 

It's based on the basic concepts of git workflow.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
