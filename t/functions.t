use Modern::Perl;
use Test::More;

use_ok("Bitbankcc::Unofficial::Functions", ":all");

my $btc = 1;
my $yen = $btc * btc_jpy();
ok $yen > 1000;

done_testing;
