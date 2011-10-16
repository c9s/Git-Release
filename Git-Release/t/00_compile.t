use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Git::Release' }

my $re = Git::Release->new( );

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );
