package XML::Feed::Aggregator::Sort;
use Moose::Role;
requires 'sort_entries';

sub sort_by_date {
   my ($self) = @_;

   $self->sort_entries(sub {
            my $adt = $_[0]->issued || $_[0]->modified;
            my $bdt = $_[1]->issued || $_[1]->modified;
            return $adt->compare($bdt);
        });

    return $self;
}

sub sort_by_date_ascending {
    my ($self) = @_;
    
    $self->sort_entries(sub {
            my $adt = $_[0]->issued || $_[0]->modified;
            my $bdt = $_[1]->issued || $_[1]->modified;
            return $bdt->compare($adt);
        });

    return $self;
}

1;
__END__

=head1 NAME

XML::Feed::Aggregator::Sort - Role for sorting feed entries

=head1 SYNOPSIS

  # builtin sort methods:

  $aggregator->sort_by_date_ascending;
  $aggregator->sort_by_date;

  # custom sort routine

  $aggregator->sort_entries(sub {
    $_[0]->title cmp $_[1]->title
  });

=head1 METHODS

=head2 sort_entries

=head2 sort_by_date

=head2 sort_by_date_ascending

=head1 CONTRIBUTE

git://github.com/robinedwards/XM-Feed-Aggregator.git

=head1 SEE ALSO

XML::Feed::Aggregator XML::Feed::Aggregator::Sort

=head1 AUTHOR

Robin Edwards, E<lt>robin.ge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5 or,
at your option, any later version of Perl 5 you may have available.

=cut
