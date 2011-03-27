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

sub sort {
    my ($self, $order) = @_;

    warn "Called deprecated method ->sort";

    if ($order eq 'desc') {
        $self->sort_by_date;
    }
    else {
        $self->sort_by_date_ascending;
    }

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

Provide your own sorting routine via a CodeRef, two entries provided as arguments.

=head2 sort_by_date

Sort entries with date in descending order.

=head2 sort_by_date_ascending

Sort entries with date in ascending order.

=head1 SEE ALSO

L<XML::Feed::Aggregator>

L<XML::Feed::Aggregator::Deduper>

=cut
