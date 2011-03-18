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

our $VERSION = 0.0400;

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
        sort_entries => 'sort_in_place',
        map_entries => 'map',
        entry_count => 'count',
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

    return $self;
}

sub aggregate {
    my ($self) = @_;

    return $self if $self->entry_count > 0;

    for my $feed ($self->all_feeds) {
        $self->add_entry($feed->entries);
    }

    $self->grep_entries(sub { defined $_ });

    return $self;
}

sub grep_entries {
    my ($self, $filter) = @_;

    my @entries = grep { $filter->($_) } $self->all_entries;
    $self->entries(\@entries);

    return $self;
}

sub to_feed {
    my ($self, @params) = @_;

    my $feed = XML::Feed->new(@params);

    for my $entry ($self->all_entries) {
        $feed->add_entry($entry);
    }

    return $feed;
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator - Simple feed aggregator

=head1 SYNOPSIS

    use XML::Feed::Aggregator;

    my $syndicator = XML::Feed::Aggregator->new(
        sources => [
            "http://blogs.perl.org/atom.xml",
            "http://news.ycombinator.com/"
        ],
        feeds => [ XML::Feed->parse('./slashdot.rss') ]
    
    )->fetch->aggregate->deduplicate->sort;

    # Also.. 

    $syndicator->grep_entries(sub {
        $_->author ne 'James'
    })->deduplicate;

    say $syndicator->map_entries(sub { $_->title } );

=head1 DESCRIPTION

This module aggregates feeds from different sources for easy filtering and sorting.

=head1 ATTRIBUTES

=head2 sources

Sources to be fetched / loaded into the feeds attribute.

Coerces to an ArrayRef of URI objects.

=head2 feeds

An ArrayRef of XML::Feed objects.

=head2 entries

List of XML::Feed::Entry objects obtained from the sources

=head1 METHODS

=head2 fetch

Convert each source into an XML::Feed object, via XML::Feed->parse()

For a remote address this involves fetching.

=head2 aggregate

Add all entries to the shared 'entries' attribute

=head1 FEED METHODS
=head2 add_feeds
=head2 all_feeds
=head2 feed_count

=head1 ENTRY METHODS
=head2 sort_entries
=head2 map_entries
=head2 grep_entries
=head2 add_entry
=head2 entry_count
=head2 all_entrys

=head1 ERROR HANDLING

=head2 error_count

Number of errors occured fetching / parsing feeds.

=head2 errors

An ArrayRef of errors whilst fetching / parsing feeds.

=head1 SEE ALSO

Perlanet XML::Feed Feed::Find

=head1 AUTHOR

Robin Edwards, E<lt>robin.ge@gmail.comE<gt>

@robingedwards http://github.com/robinedwards/

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 - 2011 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
