use Modern::Perl;
use Test::More;
use Test::Internet;

use_ok("Bitbankcc::Unofficial");

plan skip_all => "No internet connection." unless connect_ok();

my $res = Bitbankcc::Unofficial->new->ticker( pair => 'btc_jpy' );
ok $res->{data}{last} > 100;

done_testing;
