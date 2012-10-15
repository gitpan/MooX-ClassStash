package TestMooXClassStashMooX;

use MooX qw(
	ClassStash
);

has i => (
	is => 'ro',
	default => sub {1},
);

1;