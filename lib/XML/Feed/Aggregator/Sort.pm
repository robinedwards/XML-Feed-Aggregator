package XML::Feed::Aggregator::Sort;
use Moose::Role;
use Data::Dumper;
use namespace::autoclean;

requires 'all_entries';
requires 'add_entry';

sub sort_by_date {
    $_[0]->sort(sub {
            my $adt = $a->issued || $a->modified;
            my $bdt = $b->issued || $b->modified;
            $adt->compare($bdt);
        });
    return $_[0];
}

sub sort_by_date_ascending {
    $_[0]->sort(sub {
            my $adt = $a->issued || $a->modified;
            my $bdt = $b->issued || $b->modified;
            $bdt->compare($adt);
        });
    return $_[0];
}

sub sort {
    my ($self, $order) = @_;

    $self->_combine_feeds;
    $self->add_entry(sort $order $self->all_entries);
    
    return $self;
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator::Deduper - Perl module for aggregating feeds

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

  my $d = $agg->deduplicate;
  say "removed $d duplicates";

  # loop through XML::Feed::Entry objects 
  for ($agg->entries) {
      say $_->title;
      say $_->content;
  }

  # get new aggregated XML::Feed object
  my $feed = $agg->feed;

  # loop through errors;
  warn $_ for ($agg->errors);

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

sort feed by date

=head2 deduplicate

removed duplicated entries from the feed

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

git://github.com/robinedwards/XM-Feed-Aggregator.git

=head1 SEE ALSO

XML::Feed XML::Feed::Deduper Feed::Find

=head1 AUTHOR

Robin Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
