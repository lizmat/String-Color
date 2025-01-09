use Array::Sorted::Util:ver<0.0.11+>:auth<zef:lizmat>;

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

class String::Color:ver<0.0.11>:auth<zef:lizmat> {
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

# vim: expandtab shiftwidth=4
