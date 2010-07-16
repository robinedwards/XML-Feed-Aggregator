package XML::Feed::Aggregator;
use 5.00800;
use strict;
use warnings;
use Carp;
use URI;
use XML::Feed;
use DateTime;
use Try::Tiny;

our $VERSION = 0.03;

sub new {
    my ($class, $self) = @_;

    croak 'expecting HashRef' unless ref $self eq 'HASH';

    bless ($self, $class);

    $self->_coerce_sources(delete $self->{sources})
        or
    croak 'Missing sources';

    $self->{errors} = [];
    $self->{new_feed}{type} ||= ['RSS'];

    return $self;
}

sub _coerce_sources {
    my ($self, $sources) = @_;
    
    croak 'sources should be an ArrayRef'
        if ref $sources ne 'ARRAY';

    $self->{_sources} = [];

    for (@$sources) {
        next unless $_;

        if (ref ($_) =~ /^XML::Feed/ || ref ($_) =~ /^URI/) {
            push @{$self->{_sources}}, $_;
            next;
        }

        if (ref ($_) eq '') {
            push @{$self->{_sources}}, URI->new($_);
            next;
        }

        croak "expecting ArrayRef of XML::Feed / URI / Strings in sources";
    }

    return scalar @{$self->{_sources}};
}

sub _build_feed_list {
    my ($self) = @_;

    for my $feed (@{$self->{_sources}}) {

        if (ref ($feed) =~ /XML::Feed/) {
            push @{$self->{sources}}, $_;
            next;
        }

        if (ref ($feed) =~ /URI/) {
            my $xml_feed;

            try { $xml_feed = XML::Feed->parse($feed) }

            catch {
                push @{$self->{errors}},  $feed->as_string." failed: $_"; 
            };

            if (XML::Feed->errstr) {
                push @{$self->{errors}}, 
                    $feed->as_string." failed: ".XML::Feed->errstr;
            }

            push @{$self->{sources}}, $xml_feed if defined $xml_feed;
            next;
        }

        croak "Couldn't create XML::Feed from a $feed";
    }
}


sub sort {
    my ($self, $direction) = @_;

    $self->_build_feed_list;
    
    for my $feed (grep {defined} @{$self->{sources}}) {
       push @{$self->{entries}}, $feed->entries
    }

    if (defined $direction and $direction =~ /^desc/i){
        @{$self->{entries}} = sort _desc_date @{$self->{entries}};
    }
    else {
        @{$self->{entries}} = sort _asc_date @{$self->{entries}};
    }

    $self->_new_feed;

    $self->{feed}->add_entry($_) for (@{$self->{entries}});
}

sub _asc_date {
    my $adt = $a->issued || $a->modified;
    my $bdt = $b->issued || $b->modified;
    $bdt->compare($adt);
}

sub _desc_date {
    my $adt = $a->issued || $a->modified;
    my $bdt = $b->issued || $b->modified;
    $adt->compare($bdt);
}

sub _new_feed {
    my ($self) = @_;

    $self->{feed} = XML::Feed->new(@{$self->{new_feed}{type}});

    croak "Couldn't create new XML::Feed object" 
        unless defined $self->{feed};

    for my $attr (qw|title link base description
        tagline author language|) {

        if( $self->{$attr} ) {
            $self->{feed}->$attr($self->{new_feed}{$attr});
        }
    }
}

sub entries { $_[0]->{entries} }

sub feed { $_[0]->{feed} }

sub sources { $_[0]->{sources} }

sub errors { $_[0]->{errors} }

sub since {
    my ($self, $date) = @_;

    croak "expecting a DateTime object" 
        unless ref $date eq 'DateTime';

    return grep {
        $date->compare($_->issued || $_->modified) < 0;
    } @{$self->entries};
}


1;
__END__

=head1 NAME

XML::Feed::Aggregator - Perl module for aggregating feeds

=head1 SYNOPSIS

  use URI;
  use XML::Feed;
  use XML::Feed::Aggregator;
  
  # construction with URIs / XML::Feed / strings
  my @sources = [ URI->new('http://rss.slashdot.org/Slashdot/slashdot'),
    'http://use.perl.org/index.rss',
    XML::Feed->parse(URI->new("http://planet.perl.org")) ];

  my $agg = XML::Feed::Aggregator->new({sources => \@sources});

  # sort entries by date
  $agg->sort;

  # or descending order

  $agg->sort('desc'); 

  # loop through XML::Feed::Entry objects 
  for ($agg->entries) {
      say $_->title;
      say $_->content;
  }

  # get new aggregated XML::Feed object
  my $feed = $agg->feed;

  # loop through errors;
  warn $_ for (@{$agg->errors});

=head1 DESCRIPTION

This module aggregates feeds into a single XML::Feed object

=head1 CONSTRUCTION

List of feeds to be aggregated:

 sources - ArrayRef of URI's, URL Strings and XML::Feed objects

Parameters for the new feed object ( see XML::Feed for more params )

 new_feed => { 
    title => 'New aggregated feed', 
    link => 'http://www.your.com/feed.rss',
    author => 'Jim Bob',
 }

=head1 METHODS

=head2 sort

sort feed by date, should be called after construction

=head2 feed

returns the new XML::Feed object

=head2 entries

return list of feed entries

=head2 sources

return list of the source XML::Feed's

=head2 since

takes a DateTime object and returns any entries since that date

=head2 errors

returns list of errors that have occured

=head1 CONTRIBUTE

git://github.com/robinedwards/XML::Feed::Aggregator.git

=head1 SEE ALSO

XML::Feed Feed::Find

=head1 AUTHOR

Robin Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
