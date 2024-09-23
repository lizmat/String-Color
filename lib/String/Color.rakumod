use Array::Sorted::Util:ver<0.0.10>:auth<zef:lizmat>;

# Default string cleaner logic.
sub clean(Str:D $string) {
    $string.comb.map({
        if "a" le $_ le "z" {
            $_
        }
        elsif "A" le $_ le "Z" {
            .lc
        }
    }).join
}

class String::Color:ver<0.0.9>:auth<zef:lizmat> {
    has &.generator is required;
    has &.cleaner is built(:bind) = &clean;
    has %!string2color;
    has %!clean2color;
    has $!lock;

    multi submethod TWEAK(--> Nil) {
        %!string2color{""} := "";
        %!clean2color{""}  := "" => (my str @ = "");
        $!lock := Lock.new;
    }
    multi submethod TWEAK(:%colors! --> Nil) {
        %!string2color := %colors;
        %!string2color{""} := "";
        %!clean2color{""}  := "" => (my str @ = "");

        for %colors.kv -> $string, $color {
            my $cleaned := &!cleaner($string);
            with %!clean2color{$cleaned} {
                inserts .value, $string;
            }
            else {
                %!clean2color{$cleaned} := $color => (my str @ = $string);
            }
        }
        $!lock := Lock.new;
    }

    # Add the given strings if they're not known yet
    method add(String::Color:D: \strings) {
        my str @added;
        $!lock.protect: {
            for strings.list -> $string {
                without %!string2color{$string} {
                    @added.push($string);
                    my $cleaned := &!cleaner($string);

                    # Already have a color
                    with %!clean2color{$cleaned} {
                        %!string2color{$string} := .key;
                        inserts %!clean2color{$cleaned}.value, $string;
                    }

                    # No color yet
                    else {
                        my $color :=
                          %!string2color{$string} := &!generator($cleaned);
                        %!clean2color{$cleaned} := $color => (my str @ = $string)
                    }
                }
            }
        }
        @added
    }

    method aliases(String::Color:D: Str:D $string) {
        my str $key = &!cleaner($string);
        $!lock.protect: {
            with %!clean2color{$key} {
                .value
            }
            else {
                Nil
            }
        }
    }
    method known(String::Color:D: Str:D $color --> Bool:D) {
        $!lock.protect: { $color ∈ %!string2color.values }
    }

    method color(String::Color:D: Str:D $string) {
        $!lock.protect: { %!string2color{$string} // Nil }
    }

    method Map(String::Color:D: --> Map:D) {
        $!lock.protect: { %!string2color.Map }
    }

    method elems(String::Color:D:) {
        $!lock.protect: { %!string2color.elems }
    }

    method strings(String::Color:D:) {
        $!lock.protect: { %!string2color.keys }
    }
    method colors( String::Color:D:) {
        $!lock.protect: { %!string2color.values }
    }
    method cleaned(String::Color:D:) {
        $!lock.protect: { %!clean2color.keys }
    }
}

=begin pod

=head1 NAME

String::Color - map strings to a color code

=head1 SYNOPSIS

=begin code :lang<raku>

use String::Color;
use Randomcolor;                # some module for randomly generating colors

my $sc = String::Color.new(
  generator => { Randomcolor.new.list.head },
  cleaner   => { .lc },         # optionally provide own cleaning logic
  colors    => %colors-so-far,  # optionally start with given set
);

my @added = $sc.add(@nicks);    # add mapping for strings in @nicks

my %colors := $sc.Map;          # set up Map with color mappings so far

say "$color is already used"
  if $sc.known($color);        # check if a color is used already

=end code

=head1 DESCRIPTION

String::Color provides a class and logic to map strings to a (random)
color code.  It does so by matching the cleaned version of a string.

The way a color is generated, is determined by the required C<generator>
named argument: it should provice a C<Callable> that will take a cleaned
string, and return a color for it.

The way a string is cleaned, can be specified with the optional
C<cleaner> named argument: it should provide a C<Callable> that will
take the string, and return a cleaned version of it.  By default, the
cleaning logic will remove any non-alpha characters, and lowercase the
resulting string.

Strings can be continuously added by calling the C<add> method.  The
current state can be obtained with the C<Map> method.  The C<known>
method can be used to see whether a color is already being used or
not.

Note that colors are described as strings.  In whichever format you would
like.  Technically, this module could be used to match strings to other
strings that would not necessarily correspond to colors.  But that's
entirely up to the fantasy of the user of this module.

Also note that by e.g. writing out the C<Map> of a C<String::Color> object
as e.g. B<JSON> to disk, and then later use that in the C<colors> argument
to C<new>, would effectively make the mapping persistent.

Finally, even though this may look like a normal hash, but all operations
are thread safe (although results may be out of date).

=head1 CLASS METHODS

=head2 new

=begin code :lang<raku>

my $sc = String::Color.new(
  generator => -> $string {
      $string eq 'liz'
        ?? "ff0000"
        !! RandomColor.new.list.head
  },
  cleaner => { .lc },         # optionally provide own cleaning logic
  colors  => %colors-so-far,  # optionally start with given set
);

=end code

The C<new> class method takes two named arguments.

=head3 :cleaner

The C<cleaner> named argument allows one to specify a C<Callable> which
is supposed to take a string, and return a cleaned version of the string.
By default, a cleaner that will remove all non-alpha characters and
return the resulting string in lowercase, will be used.

=head3 :colors

The C<colors> named argument allows one to specify a C<Hash> / C<Map> with
colors that have been assigned to strings so far.  Only the empty string
mapping to the empty string will be assumed, if not specified.

=head3 :generator

The C<generator> named argument specifies a C<Callable> that will be called
to generate a colors for the associated string (which gets passed to the
C<Callable>).  It B<must> be specified.

=head1 INSTANCE METHODS

=head2 add

=begin code :lang<raku>

my @added = $sc.add(@strings);

=end code

The C<add> instance method allows adding of strings to the colors mapping.
It takes a list of strings as the positional argument.  It returns a list
of strings that were actually added (in the order they were added).

=head2 aliases

=begin code :lang<raku>

my @aliases = $sc.aliases($string);

=end code

The C<aliases> instance method returns a sorted list of strings that are
considered aliases of the given string, because they share the same cleaned
string.

=head2 cleaned

=begin code :lang<raku>

.say for $sc.cleaned;

=end code

The C<cleaned> instance method returns the cleaned strings in the same order
as C<strings>.

=head2 colors

=begin code :lang<raku>

say "colors assigned:";
.say for $sc.colors.unique;

=end code

The C<colors> instance method returns the colors in the same order as
C<strings>.

=head2 elems

=begin code :lang<raku>

say "$sc.elems() mappings so far";

=end code

The C<elems> instance method returns the number of mappings.

=head2 known

=begin code :lang<raku>

say "$color is already used"
  if $sc.known($color);            # check if a color is used already

=end code

The C<known> instance method takes a single string for color, and returns
whether that color is already in use or not.

=head2 Map

=begin code :lang<raku>

my %colors := $sc.Map;            # create simple Associative interface

=end code

The C<Map> instance method returns the state of the mapping as a C<Map> object,
which can be bound to create an C<Associative> interface.  Or it can be used
to create a persistent version of the mapping.

=head2 strings

=begin code :lang<raku>

say "strings mapped:";
.say for $sc.strings;

=end code

The C<strings> instance method returns the strings.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Color . Comments and
Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a
L<small sponsorship|https://github.com/sponsors/lizmat/>  would mean a great
deal to me!

=head1 COPYRIGHT AND LICENSE

Copyright 2021, 2024 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
