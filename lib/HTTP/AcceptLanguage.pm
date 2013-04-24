package HTTP::AcceptLanguage;
use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.01';

my $LANGUAGE_RANGE = qr/(?:[A-Za-z]{1,8}(?:-[A-Za-z]{1,8})*|\*)/;
my $QVALUE         = qr/(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)/;

sub new {
    my($class, $header) = @_;

    my @parsed_header;
    if ($header) {
        @parsed_header = $class->_parse($header);
    }

    bless {
        header        => $header,
        parsed_header => \@parsed_header,
    }, $class;
}

sub _parse {
    my($class, $header) = @_;
    $header =~ s/\s//g; #loose

    my @elements;
    my %high_qualities;
    for my $element (split /,+/, $header) {
        my($language, $quality) = $element =~ /\A($LANGUAGE_RANGE)(?:;q=($QVALUE))?\z/;
        $quality = 1 unless defined $quality;
        next unless $language && $quality > 0;

        my($primary) = split /-/, $language;
        push @elements, {
            language            => $language,
            language_primary_lc => lc($primary),
            language_lc         => lc($language),
            quality             => $quality,
        };
        if ((not exists $high_qualities{$language}) || $quality >  $high_qualities{$language}) {
            $high_qualities{$language} = $quality;
        }
    }

    # RFC2616: The language quality factor assigned to a language-tag by the Accept-Language field is the quality value of the longest language- range in the field that matches the language-tag.
    grep {
        my $language = $_->{language};
        $high_qualities{$language} ? (
            $high_qualities{$language} == $_->{quality} ? delete $high_qualities{$language} : 0
        ) : 0;
    } @elements;
}

sub languages {
    my $self = shift;
    $self->{languages} ||= do {
        my @languages = map { $_->{language} } sort { $b->{quality} <=> $a->{quality} } @{ $self->{parsed_header} };
        \@languages;
    };
    @{ $self->{languages} };
}

sub match {
    my($self, @languages) = @_;
    my @normlized_languages = map {
        $_ ? $_ : ()
    } @languages;
    return undef unless scalar(@normlized_languages);

    unless (scalar(@{ $self->{parsed_header} })) {
        # RFC2616: SHOULD assume that all languages are equally acceptable. If an Accept-Language header is present, then all languages which are assigned a quality factor greater than 0 are acceptable.
        return $normlized_languages[0];
    }

    $self->{sorted_parsed_header} ||= [ sort { $b->{quality} <=> $a->{quality} } @{ $self->{parsed_header} } ];

    # If language-quality is the same, is a priority order of the @languages
    my %header_tags;
    my %header_primary_tags;
    my $current_quality = 0;
    for my $language (@{ $self->{sorted_parsed_header} }) {
        if ($current_quality != $language->{quality}) {
            if (scalar(%header_tags)) {
                for my $tag (@normlized_languages) {
                    return $tag if $header_tags{lc $tag};
                }
                for my $tag (@normlized_languages) {
                    return $tag if $header_primary_tags{lc $tag};
                }
            }
            $current_quality = $language->{quality};
        }

        # wildcard
        return $normlized_languages[0] if $language->{language} eq '*';

        $header_tags{$language->{language_lc}}                 = 1;
        $header_primary_tags{$language->{language_primary_lc}} = 1;
    }
    if (scalar(%header_tags)) {
        for my $tag (@normlized_languages) {
            return $tag if $header_tags{lc $tag};
        }
        for my $tag (@normlized_languages) {
            return $tag if $header_primary_tags{lc $tag};
        }
    }

    return undef; # not matched
}

1;
__END__

=encoding utf-8

=head1 NAME

HTTP::AcceptLanguage - Blah blah blah

=head1 SYNOPSIS

  use HTTP::AcceptLanguage;

=head1 DESCRIPTION

HTTP::AcceptLanguage is

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 COPYRIGHT

Copyright 2013- Kazuhiro Osawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

RFC2616, L<I18N::AcceptLanguage>

=cut
