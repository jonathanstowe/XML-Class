use v6.c;

use XML;

role XML::Class[Str :$xml-namespace, Str :$xml-namespace-prefix, Str :$xml-element] {
    my role NameX {
        has Str $.xml-name is rw;
        method xml-name() is rw returns Str {
            $!xml-name //= $.name.substr(2);
            $!xml-name;
        }
    }

    my role NodeX  {
    }

    my role AttributeX does NodeX does NameX {
    }

    my role ElementX[Bool :$from-serialise] does NodeX does NameX {
        has Bool $.from-serialise = $from-serialise;

    }

    my role ContainerX does NodeX {
        has Str $.container-name is rw;
        method container-name() is rw returns Str {
            $!container-name //= $.name.substr(2);
            $!container-name;
        }

    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-container) is export {
        $a does ContainerX;
        if $xml-container.defined && $xml-container ~~ Str {
            $a.container-name = $xml-container;
        }
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-attribute!) is export {
        $a does AttributeX;
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-element!) is export {
        $a does ElementX;
        if $xml-element.defined  && $xml-element ~~ Str {
            $a.xml-name = $xml-element;
        }
    }

    sub make-name(Attribute $attribute) returns Str {
        my $name =  do given $attribute {
            when NameX {
                $attribute.xml-name;
            }
            default {
                $attribute.name.substr(2);
            }
        }
        $name;
    }

    
    my subset PoA of Attribute where { $_ !~~ NodeX};

    multi sub serialise(Cool $val, ElementX $a) {
        my $x = XML::Element.new(name => $a.xml-name);
        $x.insert(XML::Text.new(text => $val));
        $x;
    }


    # Not sure why this works in some places and not others
    # hence the overly specific param
    multi sub serialise(Cool $val where * !~~ Positional, PoA $a) {
        $val;
    }

    # One big sub because the multis were getting out of control
    multi sub serialise(@vals, Attribute $a) {
        my @els;
        for @vals.list -> $value {
            # we always want elements so set this but some objects we want the user to choose
            # whether they get the additional container so indicate we added it.
            @els.append: serialise($value, $a ~~ ElementX ?? $a !! $a but ElementX[:from-serialise]);
        }
        if $a ~~ ContainerX {
            my $el = XML::Element.new(name => $a.container-name);
            for @els -> $item {
                $el.insert($item);
            }
            @els = ($el);
        }
        @els;
    }

    multi sub serialise(%vals, Attribute $a) {
        my @els;
        for %vals.kv -> $key, $value {
            given $a {
                when ElementX {
                    if not @els.elems {
                        @els = XML::Element.new(name => $a.xml-name);
                    }
                    @els[0].insert($key, $value);
                }
                default {
                    @els.push: ( $key => $value);
                }
            }
        }
        return @els;
    }


    multi sub serialise(XML::Class $val, Attribute $a) {
        $val.to-xml(:element, attribute => $a);
    }

    multi method to-xml() returns Str {
        self.to-xml(:document).Str;
    }
    multi method to-xml(:$document!) returns XML::Document {
        my $xe = self.to-xml(:element);
        XML::Document.new($xe);
    }

    multi sub serialise(Mu:D $val, Attribute $a, $xml-element?, $xml-namespace? ) {
        my $name = $xml-element // $val.^shortname;
        my $xe = XML::Element.new(:$name);
        if $xml-namespace.defined {
            $xe.setNamespace($xml-namespace);
        }
        for $val.^attributes -> $attribute {
            my $name = make-name($attribute);
            my $values = serialise($attribute.get_value($val), $attribute);
            for $values.list -> $value {
                given $value {
                    when XML::Element {
                        $xe.insert($value);
                    }
                    when XML::Text {
                        $xe.insert($name, $value);
                    }
                    when Pair {
                        $xe.set($_.key, $_.value);
                    }
                    default {
                        $xe.set($name, $value);
                    }
                }
            }
        }
        # Add a wrapper if asked for
        # the from-serialise is true when this was set by default
        # in the Positional serialise.
        if $a.defined && $a ~~ ElementX && !$a.from-serialise {
            my $t = XML::Element.new(name => $a.xml-name);
            $t.insert($xe);
            $xe = $t;
        }
        $xe;

    }

    multi method to-xml(:$element!, Attribute :$attribute) returns XML::Element {
        serialise(self, $attribute, $xml-element, $xml-namespace);
    }
}


# vim: expandtab shiftwidth=4 ft=perl6
