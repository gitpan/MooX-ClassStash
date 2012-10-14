#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

{
	package TestMooXClassStashModifier;
	use Moo;
	use MooX::ClassStash;

	has i => (
		is => 'ro',
		default => sub {1},
	);
}

my $test = TestMooXClassStashModifier->new;
isa_ok($test,'TestMooXClassStashModifier');

my $stash = $test->class_stash;
isa_ok($stash,'MooX::ClassStash');

my $got_called_after;
my $got_called_before;
my $got_called_around;

$stash->after_method( i => sub { $got_called_after = 1 });
$stash->before_method( i => sub { $got_called_before = 1 });
$stash->around_method( i => sub { $got_called_around = 1 });

$test->i;

ok($got_called_after,"after is called");
ok($got_called_before,"before is called");
ok($got_called_around,"around is called");

done_testing;
