package Bitbankcc::Unofficial;

our $VERSION = "0.01";

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Digest::SHA qw(hmac_sha256_hex);
use JSON::MaybeXS;
use Params::Validate qw(validate);
use Time::HiRes qw(gettimeofday);
use URI;
use URI::Template;

our $BASE_URL_PRIVATE = "https://api.bitbank.cc";
our $BASE_URL_PUBLIC  = "https://public.bitbank.cc";

has key       => ( is => 'rw', isa => Str );
has secret    => ( is => 'rw', isa => Str );
has http_tiny => ( is => 'rw', default => sub { require HTTP::Tiny; HTTP::Tiny->new } );

our $ERROR_CODES = {
    10000 => 'URLが存在しません',
    10001 => 'システムエラーが発生しました。サポートにお問い合わせ下さい',
    10002 => '不正なJSON形式です。送信内容をご確認下さい',
    10003 => 'システムエラーが発生しました。サポートにお問い合わせ下さい',
    10005 => 'タイムアウトエラーが発生しました。しばらく間をおいて再度実行して下さい',
    20001 => 'API認証に失敗しました',
    20002 => 'APIキーが不正です',
    20003 => 'APIキーが存在しません',
    20004 => 'API Nonceが存在しません',
    20005 => 'APIシグネチャが存在しません',
    30001 => '注文数量を指定して下さい',
    30006 => '注文IDを指定して下さい',
    30007 => '注文ID配列を指定して下さい',
    30009 => '銘柄を指定して下さい',
    30012 => '注文価格を指定して下さい',
    30013 => '売買どちらかを指定して下さい',
    30015 => '注文タイプを指定して下さい',
    30016 => 'アセット名を指定して下さい',
    30019 => 'uuidを指定して下さい',
    30039 => '出金額を指定して下さい',
    40001 => '注文数量が不正です',
    40006 => 'count値が不正です',
    40007 => '終了時期が不正です',
    40008 => 'end_id値が不正です',
    40009 => 'from_id値が不正です',
    40013 => '注文IDが不正です',
    40014 => '注文ID配列が不正です',
    40015 => '指定された注文が多すぎます',
    40017 => '銘柄名が不正です',
    40020 => '注文価格が不正です',
    40021 => '売買区分が不正です',
    40022 => '開始時期が不正です',
    40024 => '注文タイプが不正です',
    40025 => 'アセット名が不正です',
    40028 => 'uuidが不正です',
    40048 => '出金額が不正です',
    50003 => '現在、このアカウントはご指定の操作を実行できない状態となっております。サポートにお問い合わせ下さい',
    50004 => '現在、このアカウントは仮登録の状態となっております。アカウント登録完了後、再度お試し下さい',
    50005 => '現在、このアカウントはロックされております。サポートにお問い合わせ下さい',
    50006 => '現在、このアカウントはロックされております。サポートにお問い合わせ下さい',
    50008 => 'ユーザの本人確認が完了していません',
    50009 => 'ご指定の注文は存在しません',
    50010 => 'ご指定の注文はキャンセルできません',
    50011 => 'APIが見つかりません',
    60001 => '保有数量が不足しています',
    60002 => '成行買い注文の数量上限を上回っています',
    60003 => '指定した数量が制限を超えています',
    60004 => '指定した数量がしきい値を下回っています',
    60005 => '指定した価格が上限を上回っています',
    60006 => '指定した価格が下限を下回っています',
    70001 => 'システムエラーが発生しました。サポートにお問い合わせ下さい',
    70002 => 'システムエラーが発生しました。サポートにお問い合わせ下さい',
    70003 => 'システムエラーが発生しました。サポートにお問い合わせ下さい',
    70004 => '現在取引停止中のため、注文を承ることができません',
    70005 => '現在買注文停止中のため、注文を承ることができません',
    70006 => '現在売注文停止中のため、注文を承ることができません',
};

# https://docs.bitbank.cc/#!/Withdraw/request_withdrawal
my %specs = (
    # Ticker
    ticker => {
        uri_template => "/{pair}/ticker",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
        },
    },
    # Depth
    depth => {
        uri_template => "/{pair}/depth",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
        },
    },
    # Transactions
    transactions => {
        uri_template => "/{pair}/transactions{/yyyymmdd}",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            yyyymmdd    => 0, # 日付。例:20170225
        },
    },
    # Candlestick
    candlestick => {
        uri_template => "/{pair}/candlestick/{candle_type}/{yyyy}",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            candle_type => 1, # 以下の期間から指定 1min 5min 15min 30min 1hour 4hour 8hour 12hour 1day 1week
            yyyy        => 1, # 日付 YYYYMMDD形式またはYYYYを指定
        },
    },
    # Assets
    assets => {
        uri_template => "/user/assets",
        method => "GET",
    },
    # Order
    get_order => {
        uri_template => "/user/spot/order",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            order_id    => 1, # 注文ID
        },
    },
    create_order => {
        uri_template => "/user/spot/order",
        method => "POST",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            amount      => 1, # 注文量
            price       => 1, # 価格
            side        => 1, # buyまたはsell
            type        => 1, # 指値注文の場合はlimit、成行注文の場合はmarket
        },
    },
    cancel_order => {
        uri_template => "/user/spot/cancel_order",
        method => "POST",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            order_id    => 1, # 注文ID
        },
    },
    cancel_orders => {
        uri_template => "/user/spot/cancel_orders",
        method => "POST",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            order_ids   => 1, # 注文ID
        },
    },
    orders_info => {
        uri_template => "/user/spot/orders_info",
        method => "POST",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            order_ids   => 1, # 注文ID
        },
    },
    active_orders => {
        uri_template => "/user/spot/active_orders",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            count       => 0, # 取得する注文数
            from_id     => 0, # 取得開始注文ID
            end_id      => 0, # 取得終了注文ID
            since       => 0, # 開始UNIXタイムスタンプ
            end         => 0, # 終了UNIXタイムスタンプ
        },
    },
    # Trade
    trade_history => {
        uri_template => "/user/spot/trade_history",
        method => "GET",
        params => {
            pair        => 1, # 通貨ペア。btc_jpy, xrp_jpy, ltc_btc, eth_btc, mona_jpy, mona_btc, bcc_jpy, bcc_btc
            count       => 0, # 取得する注文数
            order_id    => 0, # 注文ID
            since       => 0, # 開始UNIXタイムスタンプ
            end         => 0, # 終了UNIXタイムスタンプ
            order       => 0, # 約定時刻順序(asc: 昇順、desc: 降順、デフォルト降順)
        },
    },
    # Withdraw
    withdrawal_account => {
        uri_template => "/user/withdrawal_account",
        method => "GET",
        params => {
            asset       => 1, # アセット名。btc, xrp, ltc, eth, mona, bcc
        },
    },
    request_withdrawal => {
        uri_template => "/user/request_withdrawal",
        method => "POST",
        params => {
            asset       => 1, # アセット名。btc, xrp, ltc, eth, mona, bcc
            uuid        => 1, # 出金アカウントのuuid
            amount      => 1, # amount 引き出し量
            otp_token   => 0, # 二段階認証トークン(設定している場合、otp_tokenかsms_tokenのどちらか一方を指定)
            sms_token   => 0, # SMS認証トークン
        },
    },
);

for my $name (keys %specs) {
    no strict 'refs';
    *$name = sub { shift->_request($specs{$name}, @_) };
}

sub _request {
    my ($self, $spec) = (shift, shift);
    my %p = $spec->{params} ? validate(@_, $spec->{params}) : ();
    my $is_private = $spec->{uri_template} =~ m{^/user/} ? 1 : 0;
    state $template_memo = {};
    my $template = $template_memo->{$spec->{uri_template}} ||= URI::Template->new(
        $is_private ? "$BASE_URL_PRIVATE/v1$spec->{uri_template}" : "$BASE_URL_PUBLIC$spec->{uri_template}"
    );
    my $uri = $template->process(\%p);
    delete @p{$template->variables};
    my $res = $self->http_tiny->request(
        $spec->{method},
        $uri,
        +{
            ( $is_private ? ( headers => $self->_make_header($uri) ) : () ),
            ( (keys %p)   ? ( data    => encode_json(\%p) )          : () ),
        },
    );
    unless ( $res->{success} ) {
        my $data = decode_json($res->{content});
        die $ERROR_CODES->{$data->{code}} || $res->{content};
    }
    decode_json($res->{content});
}

sub _make_header {
    my ($self, $uri) = @_;
    my $nonce   = join "", gettimeofday;
    my $message = $nonce . $uri->path;
    {
        'Content-Type'     => 'application/json',
        'ACCESS-KEY'       => $self->key,
        'ACCESS-NONCE'     => $nonce,
        'ACCESS-SIGNATURE' => hmac_sha256_hex($message, $self->secret),
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Bitbankcc::Unofficial - It's new $module

=head1 SYNOPSIS

    use Bitbankcc::Unofficial;
    use YAML::Syck;
    my $bb = Bitbankcc::Unofficial->new( key => "KEY', secret => "SECRET" );
    my $assets = $bb->assets->{data}{assets};
    say Dump $assets;

    use Bitbankcc::Unofficial::Functions qw(:all);
    say "1 btc = @{[ 1 * btc_yen ]} YEN";

=head1 DESCRIPTION

Bitbankcc::Unofficial is ...

=head1 LICENSE

Copyright (C) Tomohiro Hosaka.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tomohiro Hosaka E<lt>bokutin@bokut.inE<gt>

=cut

