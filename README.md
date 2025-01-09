[![Actions Status](https://github.com/lizmat/String-Color/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/String-Color/actions) [![Actions Status](https://github.com/lizmat/String-Color/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/String-Color/actions) [![Actions Status](https://github.com/lizmat/String-Color/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/String-Color/actions)

NAME
====

String::Color - map strings to a color code

SYNOPSIS
========

```raku
use String::Color;
use Randomcolor;  # some module for randomly generating colors

my $sc = String::Color.new(
  generator => { Randomcolor.new.list.head },
  cleaner   => { .lc },         # optionally provide own cleaning logic
  colors    => %colors-so-far,  # optionally start with given set
);

my @added = $sc.add(@nicks);    # add mapping for strings in @nicks

my %colors := $sc.Map;          # set up Map with color mappings so far

say "$color is already used"
  if $sc.known($color);        # check if a color is used already
```

DESCRIPTION
===========

String::Color provides a class and logic to map strings to a (random) color code. It does so by matching the cleaned version of a string.

The way a color is generated, is determined by the required `generator` named argument: it should provice a `Callable` that will take a cleaned string, and return a color for it.

The way a string is cleaned, can be specified with the optional `cleaner` named argument: it should provide a `Callable` that will take the string, and return a cleaned version of it. By default, the cleaning logic will remove any non-alpha characters, and lowercase the resulting string.

Strings can be continuously added by calling the `add` method. The current state can be obtained with the `Map` method. The `known` method can be used to see whether a color is already being used or not.

Note that colors are described as strings. In whichever format you would like. Technically, this module could be used to match strings to other strings that would not necessarily correspond to colors. But that's entirely up to the fantasy of the user of this module.

Also note that by e.g. writing out the `Map` of a `String::Color` object as e.g. **JSON** to disk, and then later use that in the `colors` argument to `new`, would effectively make the mapping persistent.

Finally, even though this may look like a normal hash, but all operations are thread safe (although results may be out of date).

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
  cleaner => { .lc },         # optionally provide own cleaning logic
  colors  => %colors-so-far,  # optionally start with given set
);
```

The `new` class method takes two named arguments.

### :cleaner

The `cleaner` named argument allows one to specify a `Callable` which is supposed to take a string, and return a cleaned version of the string. By default, a cleaner that will remove all non-alpha characters and return the resulting string in lowercase, will be used.

### :colors

The `colors` named argument allows one to specify a `Hash` / `Map` with colors that have been assigned to strings so far. Only the empty string mapping to the empty string will be assumed, if not specified.

### :generator

The `generator` named argument specifies a `Callable` that will be called to generate a colors for the associated string (which gets passed to the `Callable`). It **must** be specified.

INSTANCE METHODS
================

add
---

```raku
my @added = $sc.add(@strings);
```

The `add` instance method allows adding of strings to the colors mapping. It takes a list of strings as the positional argument. It returns a list of strings that were actually added (in the order they were added).

aliases
-------

```raku
my @aliases = $sc.aliases($string);
```

The `aliases` instance method returns a sorted list of strings that are considered aliases of the given string, because they share the same cleaned string.

cleaned
-------

```raku
.say for $sc.cleaned;
```

The `cleaned` instance method returns the cleaned strings in the same order as `strings`.

colors
------

```raku
say "colors assigned:";
.say for $sc.colors.unique;
```

The `colors` instance method returns the colors in the same order as `strings`.

elems
-----

```raku
say "$sc.elems() mappings so far";
```

The `elems` instance method returns the number of mappings.

known
-----

```raku
say "$color is already used"
  if $sc.known($color);            # check if a color is used already
```

The `known` instance method takes a single string for color, and returns whether that color is already in use or not.

Map
---

```raku
my %colors := $sc.Map;            # create simple Associative interface
```

The `Map` instance method returns the state of the mapping as a `Map` object, which can be bound to create an `Associative` interface. Or it can be used to create a persistent version of the mapping.

strings
-------

```raku
say "strings mapped:";
.say for $sc.strings;
```

The `strings` instance method returns the strings.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Color . Comments and Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

