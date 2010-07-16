use strict;
use warnings;
use Test::More 'no_plan';
use URI;
use XML::Feed::Aggregator;

# test construction from a mixed list
my $slashdot = URI->new('http://rss.slashdot.org/Slashdot/slashdot');
isa_ok($slashdot, 'URI');

my $useperl = XML::Feed->parse(URI->new('http://use.perl.org/index.rss'));
isa_ok($useperl, 'XML::Feed::Format::RSS');

my $elreg = 'http://www.theregister.co.uk/headlines.atom';

my $sources = [$slashdot,$useperl, $elreg] ;

my $agg = XML::Feed::Aggregator->new({sources=>$sources});

isa_ok($agg, 'XML::Feed::Aggregator');

$agg->sort;

my $feed = $agg->feed;
isa_ok($feed, 'XML::Feed::Format::RSS');

ok(scalar($feed->entries) > 0, 'feed count');

ok(scalar(@{$agg->errors}) == 0);

