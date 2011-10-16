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
    my $repo = shift;

    # remove remtoes names, strip star char.
    return uniq 
            map { chomp; $_; } 
            map { s/^\*?\s*//; $_; } 
                $repo->command( 'branch' , '-a' );
}

sub get_local_branches {
    my $repo = shift;
    return map { chomp; $_; } 
           map { s/^\*?\s*//; $_; } 
           $repo->command( 'branch' , '-l' );
}

sub strip_remote_names { 
    my $self = shift; 
    map { s/remotes\/.*?\///; $_ } @_;
}

# return branches with ready prefix.
sub find_ready_branches {
    my $self = shift;
    my $ready_prefix = $self->config->ready_prefix;
    my @branches = $self->get_all_branches;
    my @ready_branches = grep /$ready_prefix/, @branches;
    return @ready_branches;
}

sub update_remote_refs {
    my $self = shift; 
    $self->repo->command(qw(remote update --prune));
    $self->repo->command(qw(fetch --all --prune));
}

sub create_develop_branch {
    my $self = shift;
    my $name = $self->config->develop_branch;
    $self->repo->command( 'branch' , $name , 'master' );
}

1;
__END__

=head1 NAME

Git::Release -

=head1 SYNOPSIS

  use Git::Release;

=head1 DESCRIPTION

Git::Release is

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
