package Git::Release::RemoteManager;
use Moose;

has manager => ( is => 'rw' );

sub repo { return $_[0]->manager->repo; }

sub add { 
	my ($self,$name,$uri) = @_;
	$self->manager->repo->command('remote','add',$name,$uri);
}

sub all {
	my $self = shift;
    # provide a list context to get remote names
    my @remotes = $self->manager->repo->command('remote');
    chomp(@remotes);
    return @remotes;
}

1;
