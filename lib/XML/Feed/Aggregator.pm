package XML::Feed::Aggregator;
use 5.00800;
use strict;
use warnings;
use Carp;
use URI;
use XML::Feed;
use DateTime;

our $VERSION = 0.03;

sub new {
    my ($class, $self) = @_;

    croak 'expecting HashRef' unless ref $self eq 'HASH';

    bless ($self, $class);

    if ($self->{uri}) {
        croak 'uri attribute should be an ArrayRef'
            if ref $self->{uri} ne 'ARRAY';

        $self->_coerce_uri;
    }

    if ($self->{sources}) {
        croak 'sources parameter should be an ArrayRef'
        if ref $self->{sources} ne 'ARRAY';


        for (@{$self->{sources}}) {
            croak 'sources: expecting list of XML::Feed objects' 
            if ref $_ !~ /^XML::Feed/
        }
    }

    $self->{type} = ['RSS'];

    return $self;
}

sub _coerce_uri {
    my ($self) = @_;

    for (@{$self->{uri}}) {
        next if ref =~ /^URI/;

        croak 'uri parameter expects a string / URI' 
            if ref $_ ne '';

        $_ = URI->new($_);
    }
}

sub _build_feed_list {
    my ($self) = @_;

    for my $uri (@{$self->{uri}}) {
        my $feed = XML::Feed->parse($uri)
            or croak $uri->as_string." ".XML::Feed->errstr; 
        push @{$self->{sources}}, $feed;
    }
}


sub sort {
    my ($self) = @_;

    $self->_build_feed_list;
    
    for my $feed (@{$self->{sources}}) {
       push @{$self->{entries}}, $feed->entries
    }

    @{$self->{entries}} = 
        sort { $b->issued->compare($a->issued) } 
            @{$self->{entries}};

    $self->_new_feed;

    $self->{feed}->add_entry($_) for (@{$self->{entries}});
}

sub _new_feed {
    my ($self) = @_;

    $self->{feed} = XML::Feed->new(@{$self->{type}});

    croak "Couldn't create new XML::Feed object" 
        unless defined $self->{feed};

    for my $attr (qw|title link base description
        tagline author language|) {

        if( $self->{$attr} ) {
            $self->{feed}->$attr($self->{$attr});
        }
    }
}

sub entries { $_[0]->{entries} }

sub feed { $_[0]->{feed} }

sub sources { $_[0]->{sources} }

sub since {
    my ($self, $date) = @_;

    croak "expecting a DateTime object" 
        unless ref $date eq 'DateTime';
    
    return grep {
        $date->compare($_->issued) < 0;
    } @{$self->entries};
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator - Perl module for aggregating feeds

=head1 SYNOPSIS

  use XML::Feed::Aggregator;

  # list of URI's
  use URI;
  use XML::Feed;
  
  # construction
  my $slashdot = URI->new('http://rss.slashdot.org/Slashdot/slashdot');
  my $useperl = URI->new('http://use.perl.org/index.rss');
  my $agg = XML::Feed::Aggregator->new({uri => [$slashdot, $useperl]);

  # or a list of XML::Feed's
  $slashdot = XML::Feed->parse(
    URI->new("http://rss.slashdot.org/Slashdot/slashdot")
  );
  $useperl = XML::Feed->parse(
    URI->new('http://use.perl.org/index.rss')
  );
  $agg = XML::Feed::Aggregator->new({sources => [$slashdot, $useperl]);

  # sort entries by date
  $agg->sort;

  # loop through XML::Feed::Entry objects 
  for ($agg->entries) {
      say $_->title;
      say $_->content;
  }

  # get aggregated XML::Feed object
  my $feed = $agg->feed;

=head1 DESCRIPTION

This module aggregates feeds into a single XML::Feed object

=head1 CONSTRUCTION

 sources - array ref of XML::Feed objects
 uri - array ref of URI's or url strings

The following parameters are passed to the new aggregated feed object

  title, link, base, description, tagline, author, & language

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

=head1 CONTRIBUTE

git://github.com/robinedwards/App-Syndicator.git

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
