use Modern::Perl;
use Test::More;
use Config::Merged;
use FindBin;
use Test::Internet;

use_ok("Bitbankcc::Unofficial");

plan skip_all => "No internet connection." unless connect_ok();

my $config = Config::Merged->load_stems( {
    use_ext => 1,
    stems => [ "$FindBin::Bin/../etc/config", "$FindBin::Bin/../etc/config_local"  ]
} );
my $bb  = Bitbankcc::Unofficial->new($config);
my $res = $bb->assets;
ok grep { $_->{asset} eq 'jpy' } @{$res->{data}{assets}};

done_testing;
