use strict;
use warnings;
use Test::More 'no_plan';
use URI;
use XML::Feed::Aggregator;

# test construction from a URI list
{
    my $slashdot = URI->new('http://rss.slashdot.org/Slashdot/slashdot');
    isa_ok($slashdot, 'URI');
    my $useperl = URI->new('http://use.perl.org/index.rss');
    isa_ok($useperl, 'URI');

    my @uri = ($slashdot,$useperl) ;

    my $agg = XML::Feed::Aggregator->new({uri=>\@uri});
    isa_ok($agg, 'XML::Feed::Aggregator');
}

# test construction from list of XML::Feed's
{
    my $slashdot = XML::Feed->parse(URI->new('http://rss.slashdot.org/Slashdot/slashdot'));  
    isa_ok($slashdot, 'XML::Feed');
    my $useperl = XML::Feed->parse(URI->new('http://use.perl.org/index.rss'));
    isa_ok($useperl, 'XML::Feed');

    my $agg = XML::Feed::Aggregator->new({feeds=>[$slashdot, $useperl]});
    isa_ok($agg, 'XML::Feed::Aggregator');
}

# test construction with URI coerce
my @sources = qw| http://rss.slashdot.org/Slashdot/slashdot http://use.perl.org/index.rss |;
my $agg = XML::Feed::Aggregator->new({uri=>\@sources});
isa_ok($agg, 'XML::Feed::Aggregator');

$agg->sort;

my $feed = $agg->feed;
isa_ok($feed, 'XML::Feed');

ok(scalar($feed->entries) > 0, 'feed count');

for ($feed->entries) {
    ok($_->issued);
}
