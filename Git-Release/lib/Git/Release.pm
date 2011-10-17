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

# list all remote, all local branches
sub get_all_branches {
    my $self = shift;

    # remove remtoes names, strip star char.
    return uniq 
            map { chomp; $_; } 
            map { s/^\*?\s*//; $_; } 
                $self->repo->command( 'branch' , '-a' );
}

sub get_local_branches {
    my $self = shift;
    return map { chomp; $_; } 
           map { s/^\*?\s*//; $_; } 
           $self->repo->command( 'branch' , '-l' );
}

sub strip_remote_names { 
    my $self = shift; 
    map { s{^remotes\/.*?\/}{}; $_ } @_;
}

# return branches with ready prefix.
sub get_ready_branches {
    my $self = shift;
    my $prefix = $self->config->ready_prefix;
    my @branches = $self->get_all_branches;
    my @ready_branches = grep /$prefix/, @branches;
    return @ready_branches;
}

sub get_release_branches {
    my $self = shift;
    my $prefix = $self->config->release_prefix;
    my @branches = $self->get_all_branches;
    my @release_branches = sort grep /$prefix/, @branches;
    return @release_branches;  # release branch not found.
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

sub new_branch {
    my ( $self, %args ) = @_;
    my $branch = Git::Release::Branch->new(  
            %args, manager => $self );
    return $branch;
}




sub has_develop_branch {
    my $self = shift;
    my $dev_branch_name = $self->config->develop_branch;
    my @branches = $self->get_all_branches;
    for my $branch ( @branches ) {
        my $branch = $self->new_branch( ref => $branch );
        return 1 if $branch->name eq $dev_branch_name;
    }
    return undef;
}

sub create_develop_branch {
    my $self = shift;
    my $name = $self->config->develop_branch;
    my $branch = $self->new_branch( ref => $name );
    $branch->create( from => 'master' );
    return $branch;
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
