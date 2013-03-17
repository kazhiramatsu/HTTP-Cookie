use strict;
use warnings; 
use Test::More;
use Test::Exception::LessClever;
use Test::Time time => 1362679200; # Thu, 07 Mar 2013 18:00:00 GMT   
use HTTP::Cookie;

subtest "should parse cookies" => sub {

    my @COOKIES = (
        ' foo=123 ; bar=qwerty; baz=wibble; qux=a1',
        'foo=123; bar=qwerty; baz=wibble;',
        'foo=vixen; bar=cow; baz=bitch; qux=politician',
        'foo=a%20phrase; bar=yes%2C%20a%20phrase; baz=%5Ewibble; qux=%27',
        'num=%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D',
        ' num=%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D ; bar=qwery ; ',
        '',
        undef,
    );

    my $c = HTTP::Cookie->eat($COOKIES[0]);
    is $c->{foo}->{value}, '123'; 
    is $c->{bar}->{value}, 'qwerty';
    is $c->{baz}->{value}, 'wibble';
    is $c->{qux}->{value}, 'a1';

    $c = HTTP::Cookie->eat($COOKIES[1]);
    is $c->{foo}->{value}, '123'; 
    is $c->{bar}->{value}, 'qwerty';
    is $c->{baz}->{value}, 'wibble';

    $c = HTTP::Cookie->eat($COOKIES[2]);
    is $c->{foo}->{value}, 'vixen';
    is $c->{bar}->{value}, 'cow';
    is $c->{baz}->{value}, 'bitch';
    is $c->{qux}->{value}, 'politician';

    $c = HTTP::Cookie->eat($COOKIES[3]);
    is $c->{foo}->{value}, 'a phrase';
    is $c->{bar}->{value}, 'yes, a phrase';
    is $c->{baz}->{value}, '^wibble';
    is $c->{qux}->{value}, "'";

    $c = HTTP::Cookie->eat($COOKIES[4]);
    is $c->{num}->{value}, '!*\'();:@&=+$,/?%#[]';

    $c = HTTP::Cookie->eat($COOKIES[5]);
    is $c->{num}->{value}, '!*\'();:@&=+$,/?%#[]';
    is $c->{bar}->{value}, 'qwery';

    $c = HTTP::Cookie->eat($COOKIES[6]);
    is $c->{num}->{value}, undef;

    $c = HTTP::Cookie->eat($COOKIES[7]);
    is $c->{num}->{value}, undef;
};

subtest "should bake cookies" => sub {

    my @COOKIES = (  
        {
            num => {
                value => 'cookie',
            }
        },
        {
            num => {
                value => 123456,
                domain => 'a.b.com',
                path => '/foo/bar', 
                expires => time,
                httponly => 1,
                secure => 1,
            }
        },
        {
            '!*\'();:@&=+$,/?%#[]' => {
                value => '!*\'();:@&=+$,/?%#[]',
                path => '/foo/bar', 
                expires => time+60,
                httponly => 1,
                secure => 1,
            }
        },
        {
            num => {
                value => 123456,
                path => '/foo/bar', 
                'max-age' => '+10s',
                httponly => 1
            },
            val => {
                value => 67890,
                path => '/baz/woo', 
                expires => '+1M',
                domain => 'a.c.com',
                secure => 1
            }
        },
    );

    my $c = HTTP::Cookie->new(%{$COOKIES[0]});
    is $c->{num}->{value}, 'cookie';

    while (my($name, $val) = each %{$c->cookies}) {
        my $cookie = $c->bake($name, $val);
        is $cookie, "num=cookie";
    }

    $c = HTTP::Cookie->new(%{$COOKIES[1]});
    is $c->{num}->{value}, 123456;
    is $c->{num}->{domain}, 'a.b.com';
    is $c->{num}->{path}, '/foo/bar';
    is $c->{num}->{expires}, 'Thu, 07-Mar-2013 18:00:00 GMT';
    is $c->{num}->{httponly}, 1;
    is $c->{num}->{secure}, 1;

    while (my($name, $val) = each %{$c->cookies}) {
        my $cookie = $c->bake($name, $val);
        is $cookie, "num=123456; domain=a.b.com; path=/foo/bar; expires=Thu, 07-Mar-2013 18:00:00 GMT; secure; HttpOnly";
    }

    $c = HTTP::Cookie->new(%{$COOKIES[2]});
    is $c->{'!*\'();:@&=+$,/?%#[]'}->{value}, '!*\'();:@&=+$,/?%#[]';
    is $c->{'!*\'();:@&=+$,/?%#[]'}->{path}, '/foo/bar';
    is $c->{'!*\'();:@&=+$,/?%#[]'}->{expires}, 'Thu, 07-Mar-2013 18:01:00 GMT';
    is $c->{'!*\'();:@&=+$,/?%#[]'}->{httponly}, 1;
    is $c->{'!*\'();:@&=+$,/?%#[]'}->{secure}, 1;

    while (my($name, $val) = each %{$c->cookies}) {
        my $cookie = $c->bake($name, $val);
        is $cookie, "%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D=%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D; path=/foo/bar; expires=Thu, 07-Mar-2013 18:01:00 GMT; secure; HttpOnly";
    }

    $c = HTTP::Cookie->new(%{$COOKIES[3]});
    is $c->{num}->{value}, 123456;
    is $c->{num}->{path}, '/foo/bar';
    is $c->{num}->{'max-age'}, 10;
    is $c->{num}->{httponly}, 1;
    is $c->{val}->{value}, 67890;
    is $c->{val}->{path}, '/baz/woo';
    is $c->{val}->{expires}, 'Sat, 06-Apr-2013 18:00:00 GMT';
    is $c->{val}->{domain}, 'a.c.com';
    is $c->{val}->{secure}, 1;

    while (my($name, $val) = each %{$c->cookies}) {
        my $cookie = $c->bake($name, $val);
        if ($name eq 'num') {
            is $cookie, "num=123456; path=/foo/bar; max-age=10; HttpOnly";
        } elsif ($name eq 'val') {
            is $cookie, "val=67890; domain=a.c.com; path=/baz/woo; expires=Sat, 06-Apr-2013 18:00:00 GMT; secure";
        }
    }
};

subtest "should bake cookies with expires" => sub {

    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    my %FORMS = (
        "now"    => "Thu, 07-Mar-2013 18:00:00 GMT",
        "-1s"    => "Thu, 07-Mar-2013 17:59:59 GMT",
        "+1s"    => "Thu, 07-Mar-2013 18:00:01 GMT",
        "+180s"  => "Thu, 07-Mar-2013 18:03:00 GMT",
        "-1m"    => "Thu, 07-Mar-2013 17:59:00 GMT",
        "+1m"    => "Thu, 07-Mar-2013 18:01:00 GMT",
        "-1h"    => "Thu, 07-Mar-2013 17:00:00 GMT",
        "+1h"    => "Thu, 07-Mar-2013 19:00:00 GMT",
        "+12h"   => "Fri, 08-Mar-2013 06:00:00 GMT",
        "-1d"    => "Wed, 06-Mar-2013 18:00:00 GMT",
        "+1d"    => "Fri, 08-Mar-2013 18:00:00 GMT",
        "-1M"    => "Tue, 05-Feb-2013 18:00:00 GMT",
        "+1M"    => "Sat, 06-Apr-2013 18:00:00 GMT",
        "-2y"    => "Tue, 08-Mar-2011 18:00:00 GMT",
        "+2y"    => "Sat, 07-Mar-2015 18:00:00 GMT",
    );

    for my $form (keys %FORMS) {
        my $c = HTTP::Cookie->new(
            num => {
                value => 123456,
                path => '/HTTP/', 
                expires => $form,
                httponly => 1
            }
        );
    
        while (my($name, $val) = each %{$c->cookies}) {
            my $cookie = $c->bake($name, $val);
            is $cookie, "num=123456; path=/HTTP/; expires=$FORMS{$form}; HttpOnly";
        }
    }
};

subtest "should bake cookies with max-age" => sub {

    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)

    my %FORMS = (
        "now"    => 0,
        "-1s"    => -1, 
        "+1s"    => 1,
        "+180s"  => 180,
        "-1m"    => -60,
        "+1m"    => 60,
        "-1h"    => -60*60,
        "+1h"    => 60*60,
        "+12h"   => 60*60*12,
        "-1d"    => -60*60*24,
        "+1d"    => 60*60*24,
        "-2d"    => -60*60*24 * 2,
        "+2d"    => 60*60*24 * 2,
        "-1M"    => -60*60*24*30,
        "+1M"    => 60*60*24*30,
        "-2M"    => -60*60*24*30 * 2,
        "+2M"    => 60*60*24*30 * 2,
        "-2M"    => -60*60*24*30 * 2,
        "+2M"    => 60*60*24*30 * 2,
        "-2y"    => -60*60*24*365 * 2,
        "+2y"    => 60*60*24*365 * 2,
    );             

    for my $form (keys %FORMS) {
        my $c = HTTP::Cookie->new(
            num => {
                value => 123456,
                path => '/HTTP/', 
                'max-age' => $form,
                httponly => 1
            }
        );
    
        while (my($name, $val) = each %{$c->cookies}) {
            my $cookie = $c->bake($name, $val);
            is $cookie, "num=123456; path=/HTTP/; max-age=$FORMS{$form}; HttpOnly";
        }
    }
};

subtest "should throw exception for invalid parametes" => sub {

    throws_ok {
        my $c = HTTP::Cookie->new(
            SID => {
                hoge => '12i3jf949jhfjkekp28r9fk',
            }
        );
    } qr/Invalid parametes for hoge/; 
};

done_testing;
