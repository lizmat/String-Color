use v6.*;

use Array::Sorted::Util:ver<0.0.6>:auth<cpan:ELIZABETH>;

class String::Color:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has      &.generator is required;
    has str  @!seen                 = '';
    has str  @!color                = '';
    has Lock $!lock is built(:bind) = Lock.new;

    multi method TWEAK(--> Nil) { }
    multi method TWEAK(:%colors! --> Nil) {
        for %colors.kv -> str $string, str $color {
            without finds @!seen, $string -> $pos {
                inserts
                  @!seen,  $string,
                  @!color, $color,
                  :$pos;
            }
        }
    }

    multi method add(@strings, :&matcher! --> Nil) {
        $!lock.protect: {
            for @strings -> str $string {
                without finds @!seen, $string -> $pos {
                    inserts
                      @!seen,  $string,
                      @!color, matcher($string, @!seen[$pos])
                        ?? @!color[$pos]
                        !! &!generator($string),
                        :$pos;
                }
            }
        }
    }
    multi method add(@strings --> Nil) {
        $!lock.protect: {
            for @strings -> str $string {
                without finds @!seen, $string -> $pos {
                    inserts
                      @!seen,  $string,
                      @!color, &!generator($string),
                      :$pos;
                }
            }
        }
    }

    method known(String::Color:D: Str:D $color --> Bool:D) {
        $color (elem) @!color
    }

    proto method Map(|) {*}
    multi method Map(String::Color:D: &mapper) {
        $!lock.protect: {
            Map.new(( (^@!seen).map: -> int $pos {
                if @!color[$pos] -> $color {
                    $_ => mapper($_, $color) given @!seen[$pos]
                }
                else {
                    '' => ''
                }
            }))
        }
    }
    multi method Map(String::Color:D:) {
        $!lock.protect: {
            Map.new(( (^@!seen).map: -> int $pos {
                @!seen[$pos] => @!color[$pos]
            }))
        }
    }

    method elems(String::Color:D:)  { @!seen.elems }
    method keys(String::Color:D:)   { @!seen       }
    method values(String::Color:D:) { @!color      }
}

=begin pod

=head1 NAME

String::Color - map strings to a color code

=head1 SYNOPSIS

=begin code :lang<raku>

use String::Color;
use RandomColor;                # some module for randomly generating colors

my $sc = String::Color.new(
  generator => { RandomColor.new.list.head },
  colors    => %colors-so-far,  # optionally start with given set
);

$sc.add(@nicks);                # add mapping for strings in @nicks

my %color := $sc.Map;           # set up hash with color mappings so far

say "$color is already used"
  if $sc.known($color);         # check if a colour is used already

=end code

=head1 DESCRIPTION

String::Color provides a class and logic to map strings to a (random)
color code.  Strings can be continuously added by calling the C<add>
method.  The current state can be obtained with the C<Map> method.
The C<known> method can be used to see whether a color is already being
used or not.

Note that colors are described as strings.  In whichever format you would
like.  Technically, this module could be used to match strings to other
strings that would not necessarily correspond to colors.  But that's
entirely up to the fantasy of the user of this module.

Also note that by e.g. writing out the C<Map> of a C<Color::String> object
as e.g. B<JSON> to disk, and then later use that in the C<color> argument
to C<new>, would effectively make the mapping persistent.

=head1 CLASS METHODS

=head2 new

=begin code :lang<raku>

my $sc = String::Color.new(
  generator => -> $string {
      $string eq 'liz'
        ?? "ff0000"
        !! RandomColor.new.list.head
  },
  colors => %colors-so-far,  # optionally start with given set
);

=end code

The C<new> class method takes two named arguments.

=head3 :generator

The C<generator> named argument specifies a C<Callable> that will be called
to generate a color for the associated string (which gets passed to the
C<Callable>).  It B<must> be specified.

=head3 :colors

The C<colors> named argument allows one to specify a C<Hash> / C<Map> with
colors that have been assigned to strings so far.

=head1 INSTANCE METHODS

=head2 add

=begin code :lang<raku>

$sc.add(@strings);

$sc.add(@strings, matcher => -> $string, $next {
    ...
}

=end code

The C<add> instance method allows adding of strings to the color mapping.
It takes a list of strings as the positional argument.  It also accepts
an optional C<matcher> argument.  This argument should be a C<Callable>
that accepts two arguments: the string that hasn't been found yet, and
another string that is alphabetically just after the string that hasn't
been found.  It is expected to return C<True> if color of "next" string
should be used for the given string, or C<False> if a new color should
be generated for the string.

=head2 elems

=begin code :lang<raku>

say "$sc.elems() mappings so far";

=end code

The C<elems> instance method returns the number of mappings.

=head2 keys

=begin code :lang<raku>

say "strings mapped:";
.say for $sc.keys;

=end code

The C<keys> instance method returns the strings in alphabetical order.

=head2 known

=begin code :lang<raku>

say "$color is already used"
  if $sc.known($color);         # check if a colour is used already

=end code

The C<known> instance method takes a single string for color, and returns
whether that color is already in use or not.

=head2 Map

=begin code :lang<raku>

my %color := $sc.Map;             # create simple Associative interface

$file.IO.spurt: to-json $sc.Map;  # make mapping persistent

my %mapped := $sc.Map: -> string, $color {
    "<span style=\"$color\">$string</span>"
}

=end code

The C<Map> instance method returns the state of the mapping as a C<Map> object,
which can be bound to create an C<Associative> interface.  Or it can be used
to create a persistent version of the mapping.

It can also take an optional C<Callable> parameter to indicate mapping logic
that should be applied: this C<Callable> will be called with two positional
arguments: the string, and the associated color.  It should return should be
associated with the string.

=head2 values

=begin code :lang<raku>

say "colors assigned:";
.say for $sc.values;

=end code

The C<values> instance method returns the colors in the same order as C<keys>.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/String-Color . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
