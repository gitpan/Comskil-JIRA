#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Comskil::JWand' ) || print "Bail out!\n";
    use_ok( 'Comskil::JServer' ) || print "Bail out!\n";
    use_ok( 'Comskil::JQueue' ) || print "Bail out!\n";
    use_ok( 'Comskil::JQueue::POP' ) || print "Bail out!\n";
}

diag( "Testing Comskil::JWand $Comskil::JWand::VERSION, Perl $], $^X" );
