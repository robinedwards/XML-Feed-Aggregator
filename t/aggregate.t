use strict;
use warnings;
use Test::More 'no_plan';
use URI;
use XML::Feed::Aggregator;

my $slashdot = URI->new('http://rss.slashdot.org/Slashdot/slashdot');
isa_ok($slashdot, 'URI');
my $useperl = URI->new('http://use.perl.org/index.rss');
isa_ok($useperl, 'URI');

my @uri = ($slashdot,$useperl) ;

my $agg = XML::Feed::Aggregator->new({uri=>\@uri});
isa_ok($agg, 'XML::Feed::Aggregator');

$agg->sort;

my $feed = $agg->feed;

isa_ok($feed, 'XML::Feed');

ok(scalar($feed->entries) > 0, 'feed count');

for ($feed->entries) {
    diag $_->issued->ymd('-');
}
