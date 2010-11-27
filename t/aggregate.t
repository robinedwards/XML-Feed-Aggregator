use strict;
use warnings;
use Test::More 'no_plan';
use URI;
use Data::Dumper;
use XML::Feed;
use XML::Feed::Aggregator;

# test construction from a mixed list

my $agg = XML::Feed::Aggregator->new({
        sources => [
            'http://rss.slashdot.org/Slashdot/slashdot',
            'http://use.perl.org/index.rss',
            'http://www.theregister.co.uk/headlines.atom',
        ] 
    }
);


isa_ok($agg, 'XML::Feed::Aggregator');

$agg->fetch;

ok $agg->feed_count == 3, 'added feeds';

$agg->_combine_feeds;

$agg->sort_by_date;

$agg->deduplicate;

ok($agg->entry_count > 0, 'entry count');
ok $agg->error_count == 0, 'no errors';
