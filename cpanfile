requires 'perl', '5.10';

requires 'Modern::Perl';
requires 'Moo';
requires 'MooX::Types::MooseLike';
requires 'Digest::SHA';
requires 'JSON::MaybeXS';
requires 'Params::Validate';
requires 'URI::Template';

on 'test' => sub {
    requires 'Test::Internet';
};

on 'develop' => sub {
    requires 'Config::Merged';
};
