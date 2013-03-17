package HTTP::Cookie;
use strict;
use warnings;
use 5.008_001;
our $VERSION = 0.01;
use URI::Escape ();

my @MON  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @WDAY = qw( Sun Mon Tue Wed Thu Fri Sat );

my $REGEX = qr/^([+\-]?(?:\d+|\d*\.\d*))([smhdMy])/;

my %MULT = (
    's' => 1,
    'm' => 60,
    'h' => 60*60,
    'd' => 60*60*24,
    'M' => 60*60*24*30,
    'y' => 60*60*24*365
);

my %VALID = (
    value => 1,
    expires => 1,
    'max-age' => 1,
    secure => 1,
    httponly => 1,
    value => 1,
    domain => 1,
    path => 1
);

sub new {
    my $class = shift;

    my %args = @_;
    my $self = bless \%args, $class;
    while (my ($name, $val) = each %{$self}) {
        $val = { value => $val } unless ref $val eq 'HASH';
        map { croak("Invalid parametes for $_") unless exists $VALID{$_}; } keys %{$val};
        if (exists $val->{expires}) {
            $self->{$name}->{expires} = date($val->{expires});
        }
        if (exists $val->{'max-age'}) {
            $self->{$name}->{'max-age'} = max_age_calc($val->{'max-age'});
        }
    }
    $self;
}

sub cookies {
    my ($self) = @_;

    \%{$self};
}

sub eat {
    my ($class, $raw_cookie) = @_;

    return $class->new() unless $raw_cookie;
    my @cookies = ($raw_cookie =~ /(.*?)=(.*?)(?:;|$)/g);
    my %cookies = @cookies;
    my %results = ();
    while (my ($name, $val) = each %cookies) {
        $name =~ s/\s+//g;
        $val =~ s/\s+//g;
        $results{URI::Escape::uri_unescape($name)} = {value => URI::Escape::uri_unescape($val)};
    }
    $class->new(%results);
}

sub bake {
    my ($self, $name, $val) = @_;

    $val = { value => $val } unless ref $val eq 'HASH';
    my @cookie = ( URI::Escape::uri_escape($name) . "=" . URI::Escape::uri_escape($val->{value}) );
    push @cookie, "domain=" .  $val->{domain}    if $val->{domain};
    push @cookie, "path=" .    $val->{path}      if $val->{path};
    push @cookie, "expires=" . $val->{expires}   if defined $val->{expires};
    push @cookie, "max-age=" . $val->{"max-age"} if defined $val->{"max-age"};
    push @cookie, "secure"                       if $val->{secure};
    push @cookie, "HttpOnly"                     if $val->{httponly};
    my $cookie =  join "; ", @cookie;
}

sub date {
    my $expires = shift;

    $expires = expire_calc($expires);
    return $expires unless $expires =~ /^\d+$/;

    # all numbers -> epoch date
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($expires);
    $year +=  1900;

    return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
        $WDAY[$wday], $mday, $MON[$mon], $year, $hour, $min, $sec);
} 

sub expire_calc {
    my $time = shift;
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my $offset = 0;
    if (lc($time) eq 'now') {
        $offset = 0;
    } elsif ($time =~ /^\d+/) {
        return $time;
    } elsif ($time =~ $REGEX) {
        $offset = ($MULT{$2} || 1)*$1;
    } else {
        return $time;
    } 
    my $curtime = time; 
    return ($curtime+$offset);
}

sub max_age_calc {
    my $time = shift;

    my $offset = 0;
    if (lc($time) eq 'now') {
        $offset = 0;
    } elsif ($time =~ $REGEX) {
        $offset = ($MULT{$2} || 1)*$1;
    }
    return $offset;
}

sub croak {
    my $mess = shift;
    require Carp;
    Carp::croak($mess); 
}

__END__

=encoding utf8

=head1 NAME

HTTP::Cookie - Interface to HTTP cookies 

=head1 SYNOPSIS


=head1 DESCRIPTION

HTTP::Cookie is an interface to HTTP/1.1 cookies

=head1 AUTHOR

Kazutake Hiramatsu E<lt>hiramatsu {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 - Kazutake Hiramatsu

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

1;
