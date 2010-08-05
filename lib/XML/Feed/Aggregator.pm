package XML::Feed::Aggregator;
use 5.00800;
use strict;
use warnings;
use Carp;
use URI;
use XML::Feed;
use DateTime;
use Try::Tiny;
use Data::Dumper;

our $VERSION = 0.03;

sub new {
    my ($class, $self) = @_;

    croak 'expecting HashRef' unless ref ($self) eq 'HASH';

    croak 'sources should be an ArrayRef'
        if ref ($self->{sources}) ne 'ARRAY';

    $self->{errors} = $self->{entries} = [];

    bless ($self, $class);


    $self->_load_sources;

    $self->{new_feed}{type} ||= ['RSS'];

    return $self;
}

sub _load_sources {
    my ($self) = @_;
    
    my @feeds;

    for (grep {defined } @{$self->{sources}}) {
        next unless defined $_;

        if (ref ($_) =~ /^XML::Feed::Format/) {
            push @feeds, $_;
            next;
        }
        else {
            my ($uri, $xml_feed);

            if (ref ($_) !~ /^URI/) {
                $uri = URI->new($_);
            } else {
                $uri = $_;
            }

            next unless defined $uri;

            $xml_feed = $self->_load_feed($uri);

            push @feeds, $xml_feed
                if defined $xml_feed;
        }
    }

    $self->{sources} = \@feeds;
    return scalar(@{$self->{sources}});
}

sub _load_feed {
    my ($self, $uri) = @_;

    my $xml_feed;

    try { 
        $xml_feed = XML::Feed->parse($uri);
    }
    catch {
        push @{$self->{errors}}, $uri->as_string." failed: $_\n"; 
    }
    finally {
        push @{$self->{_sources}}, $xml_feed 
            if defined $xml_feed;
    };

    if (XML::Feed->errstr) {
        push @{$self->{errors}}, 
        $uri->as_string." - failed: ".XML::Feed->errstr."\n";
    };

    return $xml_feed;
}

sub sort {
    my ($self, $direction) = @_;

    for my $source (@{$self->{sources}}) {
        next unless defined $source and $source->can('entries');
        push @{$self->{entries}}, map { warn "adding : ".ref($_) } $source->entries;
    }

    if (defined $direction and $direction =~ /^desc/i){
        @{$self->{entries}} = sort _desc_date @{$self->{entries}};
    }
    else {
        @{$self->{entries}} = sort _asc_date @{$self->{entries}};
    }

    $self->_build_feed;

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

sub _build_feed {
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
        defined $_ and $date->compare($_->issued || $_->modified) < 0;
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
