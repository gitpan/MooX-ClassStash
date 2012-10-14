#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $default_sub = sub {1};
my $other_default_sub = sub {2};

{
	package TestMooXClassStashSimple;
	use Moo;
	use MooX::ClassStash;

	has i => (
		is => 'ro',
		default => $default_sub,
	);

	has [qw( j k )] => (
		is => 'rw',
		default => $other_default_sub,
	);

	sub add_own_data {
		my $self = shift;
		$self->class_stash->add_data(@_);
	}

	sub get_own_data {
		my $self = shift;
		$self->class_stash->get_data(@_);
	}
}

my $test = TestMooXClassStashSimple->new;
isa_ok($test,'TestMooXClassStashSimple');

my $stash = $test->class_stash;
isa_ok($stash,'MooX::ClassStash');

my $other_test = TestMooXClassStashSimple->new;
my $other_stash = $test->class_stash;
is($stash,$other_stash,'Other object has same MooX::ClassStash');

is($test->i,1,'Checking that default value still works for i');
is($test->j,2,'Checking that default value still works for j');
is($test->k,2,'Checking that default value still works for k');

$test->j(3);

is($test->j,3,'Checking that new value is set for j');
is($test->i,1,'Checking that default value still is set for i');
is($test->k,2,'Checking that default value still is set for k');

is_deeply($test->class_stash->attributes,{
	i => {
		is => 'ro',
		default => $default_sub,
	},
	j => {
		is => 'rw',
		default => $other_default_sub,
	},
	k => {
		is => 'rw',
		default => $other_default_sub,
	},
},'Proper attributes in class stash');

is($test->class_stash->get_attribute( i => 'is'),'ro','get_attribute method works with key');
is_deeply($test->class_stash->get_attribute('i'),{
	is => 'ro',
	default => $default_sub,
},'get_attribute method works without key');

is_deeply([$test->class_stash->list_all_methods],[qw(
	add_own_data
	class_stash
	get_own_data
	i
	j
	k
	new
	package_stash
)],'Proper methods in class stash');

is_deeply([$test->class_stash->list_all_keywords],[qw(
	after
	around
	before
	extends
	has
	with
)],'Proper keywords in class stash');

$test->class_stash->add_data( bla => 'blub' );

is_deeply($test->class_stash->get_data,{
	bla => 'blub'
},'Proper data in class stash for this caller');

$test->add_own_data( bla => 'wubwubwub' );

is_deeply($test->get_own_data,{
	bla => 'wubwubwub'
},'Proper data in class stash for other caller');

$test->class_stash->add_attribute( l => (
	is => 'rw',
));

$test->l(3);

is($test->l,3,'new added attribute works');
is($test->class_stash->get_attribute( l => 'is' ),'rw','get_attribute of a new added attribute works');

done_testing;
