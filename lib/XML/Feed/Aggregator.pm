package XML::Feed::Aggregator;
use 5.00800;
use strict;
use warnings;
use Carp;
use URI;
use XML::Feed;

our $VERSION = 0.01;

sub new {
    my ($class, $param) = @_;

    croak 'uri should be an array ref'
        if $param->{uri} and ref $param->{uri} ne 'ARRAY';

    for (@{$param->{uri}}) {
        croak 'expecting list of URI objects' 
            if ref $_ !~ /^URI/
    }

    for (@{$param->{feeds}}) {
        croak 'expecting list of XML::Feed objects' 
            if ref $_ ne 'XML::Feed' 
    }

    $param->{type} = ['RSS'];

    bless ($param, $class);
}

sub _build_feed_list {
    my ($self) = @_;

    for my $uri (@{$self->{uri}}) {
        my $feed = XML::Feed->parse($uri)
            or croak $uri->as_string." ".XML::Feed->errstr; 
        push @{$self->{feeds}}, $feed;
    }
}


sub sort {
    my ($self) = @_;

    $self->_build_feed_list;
    
    for my $feed (@{$self->{feeds}}) {
       push @{$self->{entries}}, $feed->entries
    }

    @{$self->{entries}} = 
        sort { $a->issued->compare($b->issued) } 
            @{$self->{entries}};

    $self->_new_feed;

    $self->{feed}->add_entry($_) for (@{$self->{entries}});
}

sub _new_feed {
    my ($self) = @_;

    $self->{feed} = XML::Feed->new(@{$self->{type}});

    croak "Couldn't create new XML::Feed object" 
        unless defined $self->{feed};

    for my $attr (qw|title link base description
        tagline author language|) {

        if( $self->{$attr} ) {
            $self->{feed}->$attr($self->{$attr});
        }
    }
}

sub entries {
    return $_[0]->{entries};
}

sub feed {
    return $_[0]->{feed};
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator - Perl module for aggregating feeds

=head1 SYNOPSIS

  use XML::Feed::Aggregator;

  # construction

  use URI;
  my $slashdot = URI->new('http://rss.slashdot.org/Slashdot/slashdot');
  my $useperl = URI->new('http://use.perl.org/index.rss');

  my $agg = XML::Feed::Aggregator->new({uri => [$slashdot, $useperl]);

  # OR 
  
  use XML::Feed;
  my $slashdot = XML::Feed->parse("http://rss.slashdot.org/Slashdot/slashdot");
  my $useperl = XML::Feed->new('http://use.perl.org/index.rss');

  my $agg = XML::Feed::Aggregator->new({feeds =>[$slashdot, $useperl]);

  # usage
  
  $agg->sort;

  for ($agg->entries) {...}  # loop through XML::Feed::Entry's 

  my $feed = $agg->feed; # get aggregated XML::Feed object

=head1 DESCRIPTION

This module aggregates feeds into a single XML::Feed object

=head1 CONSTRUCTION

Following params are passed to the final XML::Feed object

  title, link, base, description, tagline, author, & language

=head1 SEE ALSO

XML::Feed Feed::Find

=head1 AUTHOR

Robin Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
