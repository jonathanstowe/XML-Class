use v6.c;

use XML;

role XML::Class[Str :$xml-namespace, Str :$xml-namespace-prefix, Str :$xml-element] {

    # need to close over these to use within blocks that might have their own defined
    sub xml-element {
        $xml-element;
    }
    sub xml-namespace {
        $xml-namespace;
    }
    sub xml-namespace-prefix {
        $xml-namespace-prefix;
    }

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

    sub apply-namespace(Attribute $attribute) {

    }


    my role ElementWrapper {

        has Str $.xml-namespace        is rw;
        has Str $.xml-namespace-prefix is rw;

        method add-object-attribute(Mu:D $val, Attribute $attribute) {
            if $attribute.has_accessor {
                my $name = self.make-name($attribute);
                my $values = serialise($attribute.get_value($val), $attribute);
                self.add-value($name, $values);
            }
        }

        method add-wrapper(Attribute $a) returns XML::Element {
            my XML::Element $wrapped = self;
            if $a.defined && $a ~~ ElementX && !$a.from-serialise {
                my $t = create-element($a.xml-name);
                $t.insert(self);
                $wrapped = $t;
            }
            $wrapped;
        }

        method make-name(Attribute $attribute) returns Str {
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

        method add-value(Str $name, $values ) {
            for $values.list -> $value {
                given $value {
                    when XML::Element {
                        self.insert($value);
                    }
                    when XML::Text {
                        self.insert($name, $value);
                    }
                    when Pair {
                        self.set($_.key, $_.value);
                    }
                    default {
                        self.set($name, $value);
                    }
                }
            }
        }
    }

    multi sub create-element(Str:D $name, Any:U $?, Any:U $? ) returns XML::Element {
        my $x = XML::Element.new(:$name);
        $x does ElementWrapper;
        $x;
    }

    multi sub create-element(Str:D $name, Str $xml-namespace, $xml-namespace-prefix?) {
        my $xe = samewith($name);
        if $xml-namespace.defined {
            $xe.setNamespace($xml-namespace, $xml-namespace-prefix);
        }
        $xe;
    }

    
    my subset PoA of Attribute where { $_ !~~ NodeX};

    multi sub serialise(Cool $val, ElementX $a) {
        my $x = create-element($a.xml-name);
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
            my $el = create-element($a.container-name);
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
                        @els = create-element($a.xml-name);
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

    multi sub serialise(Mu:D $val, Attribute $a, $xml-element?, $xml-namespace?, $xml-namespace-prefix? ) {
        my $name = $xml-element // $val.^shortname;
        my $xe = create-element($name, $xml-namespace, $xml-namespace-prefix);
        for $val.^attributes -> $attribute {
            $xe.add-object-attribute($val, $attribute);
        }
        # Add a wrapper if asked for
        # the from-serialise is true when this was set by default
        # in the Positional serialise.
        $xe.add-wrapper($a);
    }

    multi method to-xml(:$element!, Attribute :$attribute) returns XML::Element {
        serialise(self, $attribute, $xml-element, $xml-namespace, $xml-namespace-prefix);
    }
}


# vim: expandtab shiftwidth=4 ft=perl6
