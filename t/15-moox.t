#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

eval { require MooX };

if ($@) {
	plan skip_all => "No MooX installed";
	done_testing;
	exit 0;
}

require TestMooXClassStashMooX;

my $test = TestMooXClassStashMooX->new;
isa_ok($test,'TestMooXClassStashMooX');

my $stash = $test->class_stash;
isa_ok($stash,'MooX::ClassStash');

my $other_test = TestMooXClassStashMooX->new;
my $other_stash = $test->class_stash;
is($stash,$other_stash,'Other object has same MooX::ClassStash');

is($test->i,1,'Checking that default value still works for i');

is($test->class_stash->get_attribute( i => 'is'),'ro','get_attribute method works with key');

is_deeply([$test->class_stash->list_all_methods],[qw(
	class_stash
	i
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

$test->class_stash->add_attribute( l => (
	is => 'ro',
));

is($test->class_stash->get_attribute( l => 'is' ),'ro','get_attribute of a new added attribute works');

done_testing;
