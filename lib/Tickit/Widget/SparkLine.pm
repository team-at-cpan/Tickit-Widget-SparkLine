package Tickit::Widget::SparkLine;
# ABSTRACT: Simple 'sparkline' widget implementation
use strict;
use warnings;
use parent qw(Tickit::Widget);
use POSIX qw(floor);
use List::Util qw(max);
use Tickit::Utils qw(textwidth);

our $VERSION = '0.003';

=head1 NAME

Tickit::Widget::SparkLine - minimal graph implementation for L<Tickit>

=head1 SYNOPSIS

 my $vbox = Tickit::Widget::VBox->new;
 my $widget = Tickit::Widget::SparkLine->new(
    data   => [ 0, 3, 2, 5, 1, 6, 0, 7 ]
 );
 $vbox->add($widget, expand => 1);

=head1 DESCRIPTION

Generates a mini ("sparkline") graph.

=cut

=head1 METHODS

=cut

sub lines { 1 }

sub cols {
	my $self = shift;
	return textwidth($self->data_chars);
}

=head2 new

Instantiate the widget. Takes the following named parameters:

=over 4

=item * data - graph data

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $data = delete $args{data};
	my $self = $class->SUPER::new(%args);
	$self->{data} = $data || [];
	$self->resized if $data;
	return $self;
}

=head2 data

Accessor for stored data.

With no parameters, returns the stored data as a list.

Pass either an array or an arrayref to set the data values and request display refresh.

=cut

sub data {
	my $self = shift;
	if(@_) {
		$self->{data} = [ (ref($_[0]) && reftype($_[0]) eq 'ARRAY') ? @{$_[0]} : @_ ];
		delete $self->{max_value};
		$self->resized;
	}
	return @{ $self->{data} };
}

=head2 data_chars

Returns the set of characters corresponding to the current data values. Each value
is assigned a single character, so the string length is equal to the number of data
items and represents the minimal string capable of representing all current data
items.

=cut

sub data_chars {
	my $self = shift;
	return join '', map { $self->char_for_value($_) } $self->data;
}

=head2 push

Helper method to add one or more items to the end of the list.

 $widget->push(3,4,2);

=cut

sub push : method {
	my $self = shift;
	push @{$self->{data}}, @_;
	delete $self->{max_value};
	$self->resized;
}

=head2 pop

Helper method to remove one item from the end of the list, returns the item.

 my $item = $widget->pop;

=cut

sub pop : method {
	my $self = shift;
	my $item = pop @{$self->{data}};
	delete $self->{max_value};
	$self->resized;
	return $item;
}

=head2 shift

Helper method to remove one item from the start of the list, returns the item.

 my $item = $widget->shift;

=cut

sub shift : method {
	my $self = shift;
	my $item = shift @{$self->{data}};
	delete $self->{max_value};
	$self->resized;
	return $item;
}

=head2 unshift

Helper method to add items to the start of the list. Takes a list.

 $widget->unshift(0, 1, 3);

=cut

sub unshift : method {
	my $self = shift;
	unshift @{$self->{data}}, @_;
	delete $self->{max_value};
	$self->resized;
}

=head2 splice

Equivalent to the standard Perl L<splice> function.

 # Insert 3,4,5 at position 2
 $widget->splice(2, 0, 3, 4, 5);

=cut

sub splice : method {
	my $self = shift;
	my ($offset, $length, @values) = @_;

# Specify parameters directly since splice applies a @$$@-ish prototype here
	my @items = splice @{$self->{data}}, $offset, $length, @values;
	delete $self->{max_value};
	$self->resized;
	return @items;
}

=head2 graph_steps

Returns an arrayref of characters in order of magnitude.

For example:

 [ ' ', qw(_ x X) ]

would yield a granularity of 4 steps.

Override this in subclasses to provide different visualisations - there's no limit to the number of
characters you provide in this arrayref.

=cut

sub graph_steps { [
	" ",
	"_",
	"\x{2581}",
	"\x{2582}",
	"\x{2583}",
	"\x{2584}",
	"\x{2585}",
	"\x{2586}",
	"\x{2587}",
	"\x{2588}"
] }

=head2 render

Rendering implementation. Uses L</graph_steps> as the base character set.

=cut

sub render {
	my $self = shift;
	my $win = $self->window or return;

	my $total_width = $win->cols;
	my $w = $total_width / (@{$self->{data}} || 1);
	my $floored_w = floor $w;

# Apply minimum per-cell width of 1 char
	unless($floored_w) {
		$w = 1;
		$floored_w = 1;
	}

	my $x = 0;
	foreach my $item ($self->data) {
		$win->goto(0, floor($x));
		$win->print($self->char_for_value($item) x $floored_w);
		$x += $w;
		last if floor($x) >= ($win->cols - 1);
	}

# Clear any remaining lines if we have any
	for my $line (1 .. $win->lines - 1) {
		$win->goto($line, 0);
		$win->erasech($total_width);
	}
}

=head2 char_for_value

Returns the character corresponding to the given data value.

=cut

sub char_for_value {
	my $self = shift;
	my $item = shift;
	my $range = $#{$self->graph_steps};
	return $self->graph_steps->[$item * $range / $self->max_value];
}

=head2 max_value

Returns the maximum value seen so far, used for autoscaling.

=cut

sub max_value {
	my $self = shift;
	return $self->{max_value} if exists $self->{max_value};
	return $self->{max_value} = max($self->data);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Same license and copyright as L<Tickit>.

