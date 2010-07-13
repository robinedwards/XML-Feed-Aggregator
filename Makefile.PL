use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XML::Feed::Aggregator',
    VERSION_FROM      => 'lib/XML/Feed/Aggregator.pm', # finds $VERSION
    PREREQ_PM         => {
        URI => 0,
        Carp => 0,
        XML::Feed => 0,
        Test::More => 0,
        DateTime => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/Feed/Aggregator.pm', # retrieve abstract from module
       AUTHOR         => 'Robin Edwards <rge@cpan.org>') : ()),
);
