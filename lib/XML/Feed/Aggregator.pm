package XML::Feed::Aggregator;
use Moose;
use MooseX::Types::Moose qw/ArrayRef Str/;
use MooseX::Types -declare => [qw/
    Sources Feed AtomFeed AtomEntry 
    RSSFeed RSSEntry Feeds Entry
    /];
use MooseX::Types::URI 'Uri';
use Moose::Util::TypeConstraints;
use URI;
use XML::Feed;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = 0.040;

class_type RSSEntry, {class => 'XML::Feed::Entry::Format::RSS'};
class_type AtomEntry, {class => 'XML::Feed::Entry::Format::Atom'};
class_type AtomFeed, {class => 'XML::Feed::Format::RSS'};
class_type RSSFeed, {class => 'XML::Feed::Format::Atom'};

subtype Sources,
    as ArrayRef[Uri];

coerce Sources,
    from ArrayRef[Str],
    via {
        [ map { Uri->coerce($_) } @{$_} ]
    };

subtype Feed,
    as AtomFeed|RSSFeed,
    message { "$_ is not a Feed!" };

subtype Entry,
    as AtomEntry|RSSEntry,
    message { "$_ is not an Entry!" };

has sources => (
    is => 'rw',
    isa => Sources,
    traits => [qw/Array/],
    default => sub { [] },
    coerce => 1,
    handles => {
        all_sources => 'elements',
        add_source => 'push',
    },
);

has feeds => (
    is => 'rw',
    isa => ArrayRef[Feed],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        all_feeds => 'elements',
        add_feed => 'push',
        feed_count => 'count',
    },
);

has entries => (
    is => 'rw',
    isa => ArrayRef[Entry],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        all_entries => 'elements',
        add_entry => 'push',
        entry_count => 'count',
        shift => 'shift',
        sort_entries => 'sort_in_place',
        map => 'map',
    }
);

has _errors => (
    is => 'rw',
    isa => ArrayRef[Str],
    traits => [qw/Array/],
    default => sub { [] },
    handles => {
        errors => 'elements',
        error_count => 'count',
        add_error => 'push',
    }
);

with 'XML::Feed::Aggregator::Sort';
with 'XML::Feed::Aggregator::Deduper';

use Data::Dumper;

sub fetch {
    my ($self) = @_;

    for my $uri ($self->all_sources) {
        try {
            $self->add_feed(XML::Feed->parse($uri));
        }
        catch {
            $self->add_error($uri->as_string." - failed: $_"); 
        };
    }

    $self->_combine_feeds;

    return $self;
}

sub _combine_feeds {
    my ($self) = @_;

    return if $self->entry_count > 0;

    for my $feed ($self->all_feeds) {
        $self->add_entry(
            $feed->entries
        );
    }

    $self->grep_entries(sub { defined $_ });
}

sub grep_entries {
    my ($self, $filter) = @_;

    my @entries = grep { $filter->($_) } $self->all_entries;
    $self->entries(\@entries);

    return $self;
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator - Perl module for aggregating feeds

=head1 SYNOPSIS

  use URI;
  use XML::Feed;
  use XML::Feed::Aggregator;
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
