#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
	package TestMooXClassStashLoad;
	use Moo;
	use MooX::ClassStash;
}

my $obj = TestMooXClassStashLoad->new;
isa_ok($obj,'TestMooXClassStashLoad');

done_testing;