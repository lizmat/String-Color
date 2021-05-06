NAME
====

String::Color - map strings to a color code

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

String::Color provides a class and logic to map strings to a (random) color code. Strings can be continuously added by calling the `add` method. The current state can be obtained with the `Map` method. The `known` method can be used to see whether a color is already being used or not.

Note that colors are described as strings. In whichever format you would like. Technically, this module could be used to match strings to other strings that would not necessarily correspond to colors. But that's entirely up to the fantasy of the user of this module.

Also note that by e.g. writing out the `Map` of a `Color::String` object as e.g. **JSON** to disk, and then later use that in the `color` argument to `new`, would effectively make the mapping persistent.

CLASS METHODS
=============

new
---

```raku
my $sc = String::Color.new(
  generator => -> $string {
      $string eq 'liz'
        ?? "ff0000"
        !! RandomColor.new.list.head
  },
  colors => %colors-so-far,  # optionally start with given set
);
```

The `new` class method takes two named arguments.

### :generator

The `generator` named argument specifies a `Callable` that will be called to generate a color for the associated string (which gets passed to the `Callable`). It **must** be specified.

### :colors

The `colors` named argument allows one to specify a `Hash` / `Map` with colors that have been assigned to strings so far.

INSTANCE METHODS
================

add
---

```raku
$sc.add(@strings);

$sc.add(@strings, matcher => -> $string, $next {
    ...
}
```

The `add` instance method allows adding of strings to the color mapping. It takes a list of strings as the positional argument. It also accepts an optional `matcher` argument. This argument should be a `Callable` that accepts two arguments: the string that hasn't been found yet, and another string that is alphabetically just after the string that hasn't been found. It is expected to return `True` if color of "next" string should be used for the given string, or `False` if a new color should be generated for the string.

known
-----

```raku
say "$color is already used"
  if $sc.known($color);         # check if a colour is used already
```

The `known` instance method takes a single string for color, and returns whether that color is already in use or not.

Map
---

```raku
my %color := $sc.Map;             # create simple Associative interface

$file.IO.spurt: to-json $sc.Map;  # make mapping persistent
```

The `Map` instance method returns the state of the mapping as a `Map` object, which can be bound to create an `Associative` interface. Or it can be used to create a persistent version of the mapping.

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/String-Color . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

