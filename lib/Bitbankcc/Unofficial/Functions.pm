package Bitbankcc::Unofficial::Functions;

use Bitbankcc::Unofficial;
use Exporter qw(import);

my @pairs = qw(btc_jpy xrp_jpy ltc_btc eth_btc mona_jpy mona_btc bcc_jpy bcc_btc);
our @EXPORT_OK   = @pairs;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our %MEMO = {};
for my $pair (@pairs) {
    no strict 'refs';
    *{$pair} = sub { $MEMO{$pair} ||= _request($pair) };
}

sub _request {
    my ($pair) = @_;
    Bitbankcc::Unofficial->new->ticker( pair => $pair )->{data}{last};
}

1;
