package XML::Feed::Aggregator::Deduper;
use Moose::Role;
use MooseX::Types::Moose qw/Int HashRef/;
use HTML::Scrubber;
use namespace::autoclean;

requires 'add_entry';
requires 'all_entries';
requires 'grep_entries';

has body_register => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        _register_body_sig => 'set',
        _body_sig_exists => 'exists'
    }
);

has title_register => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        _register_title_sig => 'set',
        _title_sig_exists => 'exists'
    }
);

has id_register => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        _register_id => 'set',
        _id_exists => 'exists'
    }
);

sub deduplicate {
    my ($self) = @_;
    $self->grep_entries( sub { $self->_register($_) } );
    return $self;
}

sub _register {
    my ($self, $entry) = @_;

    my $body = length($entry->content->body || '') 
        >= length($entry->summary->body || '')
        ? $entry->content->body : $entry->summary->body;

    my $body_sig = HTML::Scrubber->new->scrub($body);

    $body_sig =~ s/^\s+|\s+$//g;
    $body_sig =~ s/\s+/ /g;

    my $title_sig = $entry->title;
    $title_sig =~ s/^\s+|\s+$//g;

    return if $self->_id_exists($entry->id);
    $self->_register_id($entry->id, 1);
    return if $self->_title_sig_exists($title_sig);
    $self->_register_title_sig($title_sig, 1);
    return if $self->_body_sig_exists($body_sig);
    $self->_register_body_sig($body_sig, 1);

    return 1;
}

1;

__END__

=head1 NAME

XML::Feed::Aggregator::Deduper - role for deduplication

=head1 METHODS

=head2 deduplicate

deduplicates entries in aggregator object.

=head1 CODE

git://github.com/robinedwards/XML-Feed-Aggregator.git

=head1 SEE ALSO

XML::Feed::Aggregator

=head1 AUTHOR

Robin Edwards, E<lt>robin.ge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Robin Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
