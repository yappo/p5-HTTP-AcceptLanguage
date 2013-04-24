use strict;
use warnings;
use Test::More;

use HTTP::AcceptLanguage;

subtest 'empty' => sub {
    subtest 'undef' => sub {
        my $parser = HTTP::AcceptLanguage->new;
        is_deeply [ $parser->languages ], [];
    };
    subtest 'string' => sub {
        my $parser = HTTP::AcceptLanguage->new('');
        is_deeply [ $parser->languages ], [];
    };
    subtest 'format error' => sub {
        my $parser = HTTP::AcceptLanguage->new(';q=1');
        is_deeply [ $parser->languages ], [];
    };
    subtest 'language tag error' => sub {
        my $parser = HTTP::AcceptLanguage->new('23');
        is_deeply [ $parser->languages ], [];

        $parser = HTTP::AcceptLanguage->new('en-23');
        is_deeply [ $parser->languages ], [];

        $parser = HTTP::AcceptLanguage->new('12-34');
        is_deeply [ $parser->languages ], [];
    };
    subtest 'zero quality' => sub {
        my $parser = HTTP::AcceptLanguage->new('en;q=0');
        is_deeply [ $parser->languages ], [];

        $parser = HTTP::AcceptLanguage->new('en-us;q=0,ja;q=0,foo-bar-baz;q=0');
        is_deeply [ $parser->languages ], [];
    };
};

subtest 'simple' => sub {
    my $parser = HTTP::AcceptLanguage->new('en');
    is_deeply [ $parser->languages ], [qw / en /];

    $parser = HTTP::AcceptLanguage->new('en-US');
    is_deeply [ $parser->languages ], [qw/ en-US /];

    $parser = HTTP::AcceptLanguage->new('*');
    is_deeply [ $parser->languages ], [qw/ * /];
};

subtest 'quality' => sub {
    my $parser = HTTP::AcceptLanguage->new('en, ja;q=0.3, da;q=1');
    is_deeply [ $parser->languages ], [qw / en da ja /];

    $parser = HTTP::AcceptLanguage->new('en, ja;q=0.3, da;q=1, *;q=0.29, ch-tw');
    is_deeply [ $parser->languages ], [qw / en da ch-tw ja * /];
};

subtest 'dupe languages' => sub {
    my $parser = HTTP::AcceptLanguage->new('en, ja;q=0.3, en=0.1');
    is_deeply [ $parser->languages ], [qw / en ja /];
    $parser = HTTP::AcceptLanguage->new('en, ja;q=0.3, en=0.1, en;q=1, en;q=1.0, en;q=1.00, en;q=1.000, en;q=1');
    is_deeply [ $parser->languages ], [qw / en ja /];
    $parser = HTTP::AcceptLanguage->new('en;q=0.4, ja;q=0.3, ja;q=0.45, en;q=0.42, ja;q=0.1');
    is_deeply [ $parser->languages ], [qw / ja en /];
};

subtest 'loose' => sub {
    my $parser = HTTP::AcceptLanguage->new("en   \t , en;q=1., aaaaaaaaaaaaaaaaa, s.....dd, po;q=asda,
 ja \t   ;  \t   q \t  =  \t  0.3, da;q=1.\t\t\t,  de;q=0.");
    is_deeply [ $parser->languages ], [qw / en da ja /];
};

done_testing;
