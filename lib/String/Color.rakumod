use v6.*;

use Array::Sorted::Util:ver<0.0.6>:auth<cpan:ELIZABETH>;
use OO::Monitors;

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

monitor String::Color:ver<0.0.5>:auth<cpan:ELIZABETH> {
    has      &.generator        is required;
    has      &.cleaner is built(:bind) = &clean;
    has str  @.strings is built(False) = '';
    has str  @.colors  is built(False) = '';
    has str  @.cleaned is built(False) = '';

    multi method TWEAK(--> Nil) { }
    multi method TWEAK(:%colors! --> Nil) {
        for %colors.kv -> str $string, str $color {
            without finds @!strings, $string -> $pos {
                inserts @!strings, $string,
                        @!colors,  $color,
                        @!cleaned, &!cleaner($string),
                        :$pos;
            }
        }
    }

    # Return the color for a cleaned string.  If there is
    # no color yet, create one with the generator.
    method !color-for-cleaned(str $cleaned) {
        with @!cleaned.first($cleaned, :k) -> int $pos {
            @!colors[$pos]
        }
        else {
            &!generator($cleaned)
        }
    }

    # Add the given strings if they're not known yet
    method add(String::Color:D: @strings) {
        my @inserted;
        for @strings -> str $string {
            without finds @!strings, $string -> $pos {
                my $cleaned := &!cleaner($string);
                my $color   := self!color-for-cleaned($cleaned);
                inserts
                  @!strings, $string,
                  @!colors,  $color,
                  @!cleaned, $cleaned,
                  :$pos;
                @inserted.push: $string => $color;
            }
        }
        @inserted
    }

    method known(String::Color:D: Str:D $color --> Bool:D) {
        $color (elem) @!colors
    }

    method color(String::Color:D: Str:D $string) {
        with finds @!strings, $string -> $pos {
            @!colors[$pos]
        }
        else {
            Nil
        }
    }

    proto method Map(|) {*}
    multi method Map(String::Color:D: &mapper --> Map:D) {
        Map.new(( (^@!strings).map: -> int $pos {
            if @!colors[$pos] -> $color {
                $_ => mapper($_, $color) given @!strings[$pos]
            }
            else {
                @!strings[$pos] => ''
            }
        }))
    }
    multi method Map(String::Color:D: --> Map:D) {
        Map.new(( (^@!strings).map: -> int $pos {
            @!strings[$pos] => @!colors[$pos]
        }))
    }

    method elems( String::Color:D:) { @!strings.elems }
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

my %colors := $sc.Map;          # set up hash with color mappings so far

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

Finally, even though this may look like a normal hash, it is different in
two ways: the keys (the C<strings> method) are always returned in
alphabetical order, and all operations are thread safe (although results
may be out of date).

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
It takes a list of strings as the positional argument.

It returns an array of C<Pair>s (where the key is the string, and the value
is the color) that were actually added.

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

The C<colors> instance method returns the colors in the same order as C<strings>.

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

$file.IO.spurt: to-json $sc.Map;  # make mapping persistent

my %mapped := $sc.Map: -> $string, $color {
    "<span style=\"$color\">$string</span>"
}

=end code

The C<Map> instance method returns the state of the mapping as a C<Map> object,
which can be bound to create an C<Associative> interface.  Or it can be used
to create a persistent version of the mapping.

It can also take an optional C<Callable> parameter to indicate mapping logic
that should be applied: this C<Callable> will be called with two positional
arguments: the string, and the associated color.  It should return a C<Str>
that should be associated with the string.

=head2 strings

=begin code :lang<raku>

say "strings mapped:";
.say for $sc.strings;

=end code

The C<strings> instance method returns the strings in alphabetical order.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/String-Color . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
