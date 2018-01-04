# NAME

Bitbankcc::Unofficial - It's new $module

# SYNOPSIS

    use Bitbankcc::Unofficial;
    use YAML::Syck;
    my $bb = Bitbankcc::Unofficial->new( key => "KEY', secret => "SECRET" );
    my $assets = $bb->assets->{data}{assets};
    say Dump $assets;

    use Bitbankcc::Unofficial::Functions qw(:all);
    say "1 btc = @{[ 1 * btc_yen ]} YEN";

# DESCRIPTION

Bitbankcc::Unofficial is ...

# LICENSE

Copyright (C) Tomohiro Hosaka.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tomohiro Hosaka <bokutin@bokut.in>
