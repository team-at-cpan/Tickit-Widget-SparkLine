#!/usr/bin/perl 
use strict;
use warnings;
use Tickit;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::SparkLine;

my $tickit = Tickit->new;
my $vbox = Tickit::Widget::VBox->new;
my @graphs = map { Tickit::Widget::SparkLine->new( data => [ 0, 1, 2, 6, 4, 3, 7 ]) } 0..7;
foreach my $g (@graphs) {
	my $hbox = Tickit::Widget::HBox->new;
	$hbox->add($g);
	$vbox->add($hbox);
}
$tickit->set_root_widget($vbox);
$tickit->run;

