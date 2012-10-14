package MooX::ClassStash;
BEGIN {
  $MooX::ClassStash::AUTHORITY = 'cpan:GETTY';
}
{
  $MooX::ClassStash::VERSION = '0.001';
}
# ABSTRACT: Extra class information for Moo 


use Moo;
use Package::Stash;
use Class::Method::Modifiers qw( install_modifier );

my %stash_cache;

sub import {
	my ( $class, @args ) = @_;
	my $target = caller;
	unless ($target->can('has')) {
		warn "Not using ".$class." on a Moo class, doing nothing";
		return;
	}
	return if defined $stash_cache{$target};
	$stash_cache{$target} = $class->new($target);
}


has class => (
	is => 'ro',
	required => 1,
);


has package_stash => (
	is => 'ro',
	lazy => 1,
	builder => 1,
	handles => [qw(
		name
		namespace
		add_symbol
		remove_glob
		has_symbol
		get_symbol
		get_or_add_symbol
		remove_symbol
		list_all_symbols
		get_all_symbols
	)],
);

sub _build_package_stash { Package::Stash->new(shift->class) }


has attributes => (
	is => 'ro',
	default => sub {{}},
);


has data => (
	is => 'ro',
	default => sub {{}},
);


has keyword_functions => (
	is => 'ro',
	default => sub {[qw(
		after
		around
		before
		extends
		has
		with
	)]},
);


sub add_keyword_functions { push @{shift->keyword_functions}, @_ }

sub BUILDARGS {
	my ( $class, @args ) = @_;
	return $_[0] if (scalar @args == 1 and ref $_[0] eq 'HASH');
	unshift @args, "class" if @args % 2 == 1;
	return { @args };
}

sub BUILD {
	my ( $self ) = @_;
	$self->add_method('class_stash', sub { return $self });
	$self->add_method('package_stash', sub { return $self->package_stash });
	$self->around_method('has',sub {
		my $orig = shift;
		my $method = shift;
		for (ref $method eq 'ARRAY' ? @{$method} : ($method)) {
			$self->attributes->{$_} = { @_ };
		}
		$orig->($method, @_);
	})
}


sub add_data {
	my $self = shift;
	my $target = caller;
	$self->data->{$target} = {} unless defined $self->data->{$target};
	my $key = shift;
	$self->data->{$target}->{$key} = shift;
}


sub get_data {
	my $self = shift;
	my $target = caller;
	return unless defined $self->data->{$target};
	my $key = shift;
	if (defined $key) {
		return $self->data->{$target}->{$key} if defined $self->data->{$target}->{$key};
	} else {
		return $self->data->{$target};
	}
}


sub remove_data {
	my $self = shift;
	my $target = caller;
	return unless defined $self->data->{$target};
	my $key = shift;
	delete $self->data->{$target}->{$key} if defined $self->data->{$target}->{$key};
}


sub add_keyword { 
	my $self = shift;
	my $keyword = shift;
	push @{$self->keyword_functions}, $keyword;
	$self->add_symbol('&'.$keyword,@_);
}

# so far no check if its not a keyword


sub get_keyword { shift->get_method(@_) }


sub has_keyword { shift->has_method(@_) }


sub remove_keyword {
	my $self = shift;
	my $keyword = shift;
	$self->keyword_functions([
		grep { $_ ne $keyword }
		@{$self->keyword_functions}
	]);
	$self->remove_method($keyword, @_);
}


sub get_or_add_keyword {
	my $self = shift;
	my $keyword = shift;
	push @{$self->keyword_functions}, $keyword;
	$self->get_or_add_method($keyword, @_)
}


sub add_attribute {
	my $self = shift;
	my $has = $self->class->can('has');
	$has->(@_);
}


sub get_attribute {
	my $self = shift;
	my $attribute = shift;
	my $key = shift;
	return unless defined $self->attributes->{$attribute};
	if ($key) {
		return $self->attributes->{$attribute}->{$key};
	} else {
		return $self->attributes->{$attribute};
	}
}


sub has_attribute {
	my $self = shift;
	my $attribute = shift;
	defined $self->attributes->{$attribute} ? 1 : 0;
}


sub remove_attribute { ... }


sub get_or_add_attribute { ... }


sub list_all_keywords {
	my $self = shift;
	my %keywords = map { $_ => 1 } @{$self->keyword_functions};
	return
		sort { $a cmp $b }
		grep { $keywords{$_} }
		$self->list_all_symbols('CODE');
}


sub add_method { shift->add_symbol('&'.(shift),@_) }


sub get_method { shift->get_symbol('&'.(shift),@_) }


sub has_method { shift->has_symbol('&'.(shift),@_) }


sub remove_method { shift->remove_symbol('&'.(shift),@_) }


sub get_or_add_method { shift->get_or_add_symbol('&'.(shift),@_) }


sub list_all_methods {
	my $self = shift;
	my %keywords = map { $_ => 1 } @{$self->keyword_functions};
	return
		sort { $a cmp $b }
		grep { !$keywords{$_} }
		$self->list_all_symbols('CODE');
}


sub after_method { install_modifier(shift->class,'after',@_) }


sub before_method { install_modifier(shift->class,'before',@_) }


sub around_method { install_modifier(shift->class,'around',@_) }

1;

__END__
=pod

=head1 NAME

MooX::ClassStash - Extra class information for Moo 

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  {
    package MyClass;
    use Moo;
    use MooX::ClassStash;

    has i => ( is => 'ro' );

    sub add_own_data { shift->class_stash->add_data(@_) }
    sub get_own_data { shift->class_stash->get_data(@_) }
  }

  my $class_stash = MyClass->class_stash;
  # or MyClass->new->class_stash

  print $class_stash->get_attribute( i => 'is' ); # 'ro'

  $class_stash->add_attribute( j => (
    is => 'rw',
  ));

  print $class_stash->list_all_methods;
  print $class_stash->list_all_keywords;

  $class_stash->add_data( a => 1 ); # caller specific
  $class_stash->add_own_data( a => 2 );

  print $class_stash->get_data('a'); # 1
  print $class_stash->get_own_data('a'); # 2

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 class

The name of the class for the class stash.

=head2 class

The L<Package::Stash> object of the given class

=head2 attributes

HashRef of all the attributes set via L<Moo/has>

=head2 data

HashRef with all the caller specific data stored.

=head2 keyword_functions

ArrayRef which contains all the functions which are marked as keywords.

=head1 METHODS

=head2 add_keyword_functions

If you dont use L</add_keyword> for installing a keyword, you might need to
call this function to add the names of the keyword functions yourself.

=head2 add_data

Adds data to your, caller specific, data context of the class. First parameter
is the key, second parameter will be the value.

=head2 get_data

Get your, caller specific, data. If you give a paramter, if will only give
back the value of this key. If none is given, you get a HashRef of all the
data stored.

=head2 remove_data

=head2 add_keyword

=head2 get_keyword

=head2 has_keyword

=head2 remove_keyword

=head2 get_or_add_keyword_keyword

=head2 add_attribute

It is the same like calling L<Moo/has> inside the package.

=head2 get_attribute

=head2 has_attribute

=head2 remove_attribute

B<Not implemented yet>

=head2 get_or_add_attribute

B<Not implemented yet>

=head2 list_all_keywords

=head2 add_method

=head2 get_method

=head2 has_method

=head2 remove_method

=head2 get_or_add_method

=head2 list_all_methods

=head2 after_method

=head2 before_method

=head2 around_method

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

