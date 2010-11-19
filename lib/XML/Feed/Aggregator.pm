package XML::Feed::Aggregator;
use Moose;
use MooseX::Types::Moose qw/ArrayRef Str/;
use MooseX::Types -declare => [qw/Feed Entry/];
use MooseX::Types::URI 'Uri';
use Moose::Util::TypeConstraints;
use URI;
use XML::Feed;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = 0.040;

class_type Entry, {isa => 'XML::Feed::Entry'};
class_type Feed, {isa => 'XML::Feed'};

has sources => (
    is => 'rw',
    isa => ArrayRef[Feed|Uri],
    traits => [qw/Array/],
    handles => {
        all_sources => 'elements',
        add_source => 'push',
    },
    builder => '_build_sources',
);

has entries => (
    is => 'rw',
    isa => ArrayRef[Entry],
    handles => {
        all_entries => 'elements',
        add_entry => 'push',
        entry_count => 'count',
    }
);

has _errors => (
    is => 'rw',
    isa => ArrayRef[Str],
    handles => {
        errors => 'elements',
        add_error => 'push',
    }
);

with 'XML::Feed::Aggregator::Sort';
with 'XML::Feed::Aggregator::Deduper';

sub _coerce_source_uri {
    my ($self, $sources) = @_;

    @$sources = grep { defined } map {
        is_Str($_) ? URI->new($_) : $_
    } @$sources;
}

sub fetch {
    my ($self) = @_;

    for my $uri (grep { $_->isa('URI') } $self->all_sources) {
        try { 
            $uri = XML::Feed->parse($uri);
        }
        catch {
            $self->add_error($uri->as_string." - failed: $_"); 
        };
    }

    $self->sources(
        grep { defined } $self->all_sources
    );

    return $self;
}

sub _combine_sources {
    my ($self) = @_;

    return if $self->entry_count > 0;

    for my $source ($self->all_sources) {
        next unless $source->can('entries');
        $source->add_entry($source->entries);
    }
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
