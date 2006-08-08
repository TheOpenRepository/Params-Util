package Params::Util;

=pod

=head1 NAME

Params::Util - Simple, compact and correct param-checking functions

=head1 SYNOPSIS

  # Import some functions
  use Params::Util qw{_SCALAR _HASH _INSTANCE};
  
  # If you are lazy, or need a lot of them...
  use Params::Util ':ALL';
  
  sub foo {
      my $object  = _INSTANCE(shift, 'Foo') or return undef;
      my $image   = _SCALAR(shift)          or return undef;
      my $options = _HASH(shift)            or return undef;
      # etc...
  }

=head1 DESCRIPTION

C<Params::Util> provides a basic set of importable functions that makes
checking parameters a hell of a lot easier

While they can be (and are) used in other contexts, the main point
behind this module is that the functions B<both> Do What You Mean,
and Do The Right Thing, so they are most useful when you are getting
params passed into your code from someone and/or somewhere else
and you can't really trust the quality.

Thus, C<Params::Util> is of most use at the edges of your API, where
params and data are coming in from outside your code.

The functions provided by C<Params::Util> check in the most strictly
correct manner known, are documented as thoroughly as possible so their
exact behaviour is clear, and heavily tested so make sure they are not
fooled by weird data and Really Bad Things.

To use, simply load the module providing the functions you want to use
as arguments (as shown in the SYNOPSIS).

To aid in maintainability, C<Params::Util> will B<never> export by
default.

You must explicitly name the functions you want to export, or use the
C<:ALL> param to just have it export everything (although this is not
recommended if you have any _FOO functions yourself with which future
additions to C<Params::Util> may clash)

=head1 FUNCTIONS

=cut

BEGIN {
	require 5.004;
}
use strict;
use overload     ();
use Exporter     ();
use Scalar::Util ();

use vars qw{$VERSION @ISA @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	$VERSION   = '0.17';
	@ISA       = 'Exporter';

	@EXPORT_OK = qw{
		_STRING     _IDENTIFIER _CLASS
		_POSINT 
		_SCALAR     _SCALAR0
		_ARRAY      _ARRAY0    _ARRAYLIKE
		_HASH       _HASH0     _HASHLIKE
		_CODE       _CODELIKE  _CALLABLE
		_INVOCANT
		_INSTANCE   _SET       _SET0
		_HANDLE
		};

	%EXPORT_TAGS = (ALL => \@EXPORT_OK);
}





#####################################################################
# Param Checking Functions

=pod

=head2 _STRING $string

The C<_STRING> function is intended to be imported into your
package, and provides a convenient way to test to see if a value is
a normal non-false string of non-zero length.

Note that this will NOT do anything magic to deal with the special
C<'0'> false negative case, but will return it.

  # '0' not considered valid data
  my $name = _STRING(shift) or die "Bad name";
  
  # '0' is considered valid data
  my $string = _STRING($_[0]) ? shift : die "Bad string";

Please also note that this function expects a normal string. It does
not support overloading or other magic techniques to get a string.

Returns the string as a conveince if it is a valid string, or
C<undef> if not.

=cut

sub _STRING ($) {
	(defined $_[0] and ! ref $_[0] and length($_[0])) ? $_[0] : undef;
}

=pod

=head2 _IDENTIFIER $string

The C<_IDENTIFIER> function is intended to be imported into your
package, and provides a convenient way to test to see if a value is
a string that is a valid Perl identifier.

Returns the string as a convenience if it is a valid identifier, or
C<undef> if not.

=cut

sub _IDENTIFIER ($) {
	(defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[^\W\d]\w*$/s) ? $_[0] : undef;
}

=pod

=head2 _CLASS $string

The C<_CLASS> function is intended to be imported into your
package, and provides a convenient way to test to see if a value is
a string that is a valid Perl class.

This function only checks that the format is valid, not that the
class is actually loaded. It also assumes "normalised" form, and does
not accept class names such as C<::Foo> or C<D'Oh>.

Returns the string as a convenience if it is a valid class name, or
C<undef> if not.

=cut

sub _CLASS ($) {
	(defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[^\W\d]\w*(?:::\w+)*$/s) ? $_[0] : undef;
}

=pod

=head2 _POSINT $integer

The C<_POSINT> function is intended to be imported into your
package, and provides a convenient way to test to see if a value is
a positive integer (of any length).

Returns the value as a convience, or C<undef> if the value is not a
positive integer.

=cut

sub _POSINT ($) {
	(defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[1-9]\d*$/) ? $_[0] : undef;
}

=pod

=head2 _SCALAR \$scalar

The C<_SCALAR> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<SCALAR> reference, with content of non-zero length.

For a version that allows zero length C<SCALAR> references, see
the C<_SCALAR0> function.

Returns the C<SCALAR> reference itself as a convenience, or C<undef>
if the value provided is not a C<SCALAR> reference.

=cut

sub _SCALAR ($) {
	(ref $_[0] eq 'SCALAR' and defined ${$_[0]} and ${$_[0]} ne '') ? $_[0] : undef;
}

=pod

=head2 _SCALAR0 \$scalar

The C<_SCALAR0> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<SCALAR0> reference, allowing content of zero-length.

For a simpler "give me some content" version that requires non-zero
length, C<_SCALAR> function.

Returns the C<SCALAR> reference itself as a convenience, or C<undef>
if the value provided is not a C<SCALAR> reference.

=cut

sub _SCALAR0 ($) {
	ref $_[0] eq 'SCALAR' ? $_[0] : undef;
}

=pod

=head2 _ARRAY $value

The C<_ARRAY> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<ARRAY> reference containing B<at least> one element of any kind.

For a more basic form that allows zero length ARRAY references, see
the C<_ARRAY0> function.

Returns the C<ARRAY> reference itself as a convenience, or C<undef>
if the value provided is not an C<ARRAY> reference.

=cut

sub _ARRAY ($) {
	(ref $_[0] eq 'ARRAY' and @{$_[0]}) ? $_[0] : undef;
}

=pod

=head2 _ARRAY0 $value

The C<_ARRAY0> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<ARRAY> reference, allowing C<ARRAY> references that contain no
elements.

For a more basic "An array of something" form that also requires at
least one element, see the C<_ARRAY> function.

Returns the C<ARRAY> reference itself as a convenience, or C<undef>
if the value provided is not an C<ARRAY> reference.

=cut

sub _ARRAY0 ($) {
	ref $_[0] eq 'ARRAY' ? $_[0] : undef;
}

=pod

=head2 _ARRAYLIKE $value

The C<_ARRAYLIKE> function tests whether a given scalar value can respond to
array dereferencing.  If it can, the value is returned.  If it cannot,
C<_ARRAYLIKE> returns C<undef>.

=cut

sub _ARRAYLIKE {
	(defined $_[0] and ref $_[0] and (
		(Scalar::Util::reftype($_[0]) eq 'ARRAY')
		or
		overload::Method($_[0], '@{}')
	)) ? $_[0] : undef;
}

=pod

=head2 _HASH $value

The C<_HASH> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<HASH> reference with at least one entry.

For a version of this function that allows the C<HASH> to be empty,
see the C<_HASH0> function.

Returns the C<HASH> reference itself as a convenience, or C<undef>
if the value provided is not an C<HASH> reference.

=cut

sub _HASH ($) {
	(ref $_[0] eq 'HASH' and scalar %{$_[0]}) ? $_[0] : undef;
}

=pod

=head2 _HASH0 $value

The C<_HASH0> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<HASH> reference, regardless of the C<HASH> content.

For a simpler "A hash of something" version that requires at least one
element, see the C<_HASH> function.

Returns the C<HASH> reference itself as a convenience, or C<undef>
if the value provided is not an C<HASH> reference.

=cut

sub _HASH0 ($) {
	ref $_[0] eq 'HASH' ? $_[0] : undef;
}

=pod

=head2 _HASHLIKE $value

The C<_HASHLIKE> function tests whether a given scalar value can respond to
hash dereferencing.  If it can, the value is returned.  If it cannot,
C<_HASHLIKE> returns C<undef>.

=cut

sub _HASHLIKE {
	(defined $_[0] and ref $_[0] and (
		(Scalar::Util::reftype($_[0]) eq 'HASH')
		or
		overload::Method($_[0], '%{}')
	)) ? $_[0] : undef;
}

=pod

=head2 _CODE $value

The C<_CODE> function is intended to be imported into your package,
and provides a convenient way to test for a raw and unblessed
C<CODE> reference.

Returns the C<CODE> reference itself as a convenience, or C<undef>
if the value provided is not an C<CODE> reference.

=cut

sub _CODE ($) {
	ref $_[0] eq 'CODE' ? $_[0] : undef;
}

=pod

=head2 _CODELIKE $value

The C<_CODELIKE> is the more generic version of C<_CODE>. Unlike C<_CODE>,
which checks for an explicit C<CODE> reference, the C<_CODELIKE> function
also includes things that act like them, such as blessed objects that
overload C<'&{}'>.

Note that in the case of objects overloaded with '&{}', you will almost
always end up also testing it in 'bool' context. As such, you will most
often want to make sure your class has the following to allow it to evaluate
to true in boolean context.

  # Always evaluate to true in boolean context
  use overload 'bool' => sub () { 1 };

Returns the callable value as a convenience, or C<undef> if the
value provided is not callable.

Note - This function was formerly known as _CODELIKE but has been renamed
for greater symmetry with the other _XXXXLIKE functions.

It will continue to work silently until end-May 2006, then with a
warning until end-August 2006, then will be deprecated.

I apologise for any inconvenience caused.

=cut

sub _CODELIKE {
	(Scalar::Util::reftype($_[0])||'') eq 'CODE'
	or
	Scalar::Util::blessed($_[0]) and overload::Method($_[0],'&{}')
	? $_[0] : undef;
}

# Will stay around until end-May, then a warning till end-Augest,
# then deprecated.
BEGIN {
	*_CALLABLE = *_CODELIKE;
}

=pod

=head2 _INVOCANT $value

This routine tests whether the given value is a valid method invocant.  If so,
the value itself is returned.  Otherwise, C<_INVOCANT> returns C<undef>.

=cut

sub _INVOCANT {
	(defined $_[0] and
		(Scalar::Util::blessed($_[0])
		or      
		# We used to check for stash definedness, but any class-like name is a
		# valid invocant for UNIVERSAL methods, so we stopped. -- rjbs, 2006-07-02
		Params::Util::_CLASS($_[0]))
	) ? $_[0] : undef;
}

=pod

=head2 _INSTANCE $object, $class

The C<_INSTANCE> function is intended to be imported into your package,
and provides a convenient way to test for an object of a particular class
in a strictly correct manner.

Returns the object itself as a convenience, or C<undef> if the value
provided is not an object of that type.

=cut

sub _INSTANCE ($$) {
	(Scalar::Util::blessed($_[0]) and $_[0]->isa($_[1])) ? $_[0] : undef;
}

=pod

=head2 _SET \@array, $class

The C<_SET> function is intended to be imported into your package,
and provides a convenient way to test for set of at least one object of
a particular class in a strictly correct manner.

The set is provided as a reference to an C<ARRAY> of objects of the
class provided.

For an alternative function that allows zero-length sets, see the
C<_SET0> function.

Returns the C<ARRAY> reference itself as a convenience, or C<undef> if
the value provided is not a set of that class.

=cut

sub _SET ($$) {
	my $set = shift;
	ref $set eq 'ARRAY' and @$set or return undef;
	foreach ( @$set ) {
		Scalar::Util::blessed($_) and $_->isa($_[0]) or return undef;
	}
	$set;
}

=pod

=head2 _SET0 \@array, $class

The C<_SET0> function is intended to be imported into your package,
and provides a convenient way to test for a set of objects of a
particular class in a strictly correct manner, allowing for zero objects.

The set is provided as a reference to an C<ARRAY> of objects of the
class provided.

For an alternative function that requires at least one object, see the
C<_SET> function.

Returns the C<ARRAY> reference itself as a convenience, or C<undef> if
the value provided is not a set of that class.

=cut

sub _SET0 ($$) {
	my $set = shift;
	ref $set eq 'ARRAY' or return undef;
	foreach ( @$set ) {
		Scalar::Util::blessed($_) and $_->isa($_[0]) or return undef;
	}
	$set;
}

=pod

=head2 _HANDLE

B<EXPERIMENTAL: SUBJECT TO CHANGE OR POSSIBLE REMOVAL>

The C<_HANDLE> function is intended to be imported into your package,
and provides a convenient way to test whether or not a single scalar
value is a file handle.

Unfortunately, in Perl the definition of a file handle can be a little
bit fuzzy, so this function is likely to be somewhat imperfect (at first
anyway).

That said, it is implement as well or better than the other file handle
detectors in existance (and we stole from the best of them).

=cut

# We're doing this longhand for now. Once everything is perfect,
# we'll compress this into something that is more efficient.
sub _HANDLE {
	my $it = shift;

	# It has to be defined, of course
	unless ( defined $it ) {
		return undef;
	}

	# Normal globs are considered to be file handles
	if ( \$it eq 'GLOB' ) {
		return $it;
	}

	# Check for a conventional IO::Handle object
	if ( Scalar::Util::blessed($it) and $it->isa('IO::Handle') ) {
		return $it;
	}

	# Check for a normal tied filehandle
	# Side Note: 5.5.4's tied() and can() doesn't like getting undef
	if ( tied($it) and tied($it)->can('TIEHANDLE') ) {
		return $it;
	}

	# Dunno... no?
	return undef;
}

=pod

=head1 TO DO

- Add _CAN to help resolve the UNIVERSAL::can debacle

- More comprehensive tests for _SET and _SET0

- Would be nice if someone would re-implement in XS for me? (done'ish)

- Would be even nicer if someone would demonstrate how the hell to
build a Module::Install dist of the ::Util dual Perl/XS type. :/

- Implement an assertion-like version of this module, that dies on
error.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Util>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
