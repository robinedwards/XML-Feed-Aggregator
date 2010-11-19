use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('XML::Feed::Aggregator') };
use_ok('XML::Feed::Aggregator::Sort');
use_ok('XML::Feed::Aggregator::Deduper');
