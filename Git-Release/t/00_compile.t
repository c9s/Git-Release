use strict;
use Test::More;

BEGIN { 
    use_ok 'Git::Release';
    use_ok 'Git::Release::Config';
}

my $re = Git::Release->new( );

ok( $re );
ok( $re->repo );
is( 'Git', ref( $re->repo ) );

ok( $re->config );
ok( $re->config->repo );
is( 'Git' , ref( $re->config->repo ));


done_testing;
