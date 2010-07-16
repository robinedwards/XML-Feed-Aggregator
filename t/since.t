use strict;
use warnings;
use Test::More 'no_plan';
use_ok 'DateTime';
use_ok 'DateTime::Duration';
use_ok 'XML::Feed::Aggregator';

my @sources = qw| http://rss.slashdot.org/Slashdot/slashdot http://use.perl.org/index.rss |;
my $agg = XML::Feed::Aggregator->new({sources=>\@sources});
isa_ok($agg, 'XML::Feed::Aggregator');

$agg->sort;

my $latest_entry = shift @{$agg->entries};

my $last = $latest_entry->issued; 
isa_ok($last, 'DateTime');

my $tother_day = $last - DateTime::Duration->new(days=>1);

isa_ok($tother_day, 'DateTime');

my @entries = $agg->since($tother_day);

# must be at least one entry
ok(scalar(@entries));

for (@entries) {
    isa_ok($_, 'XML::Feed::Entry');
}
