use v6.c;

use XML;

role XML::Class[Str :$xml-namespace, Str :$xml-element] {
    my role NameX {
        has Str $.xml-name;
        method xml-name() returns Str {
            $!xml-name.defined ?? $!xml-name !! $.name.substr(2);
        }
    }

    my role NodeX does NameX {
    }

    my role AttributeX does NodeX {
    }

    my role ElementX does NodeX {

    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-attribute!) is export {
        $a does AttributeX;
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-element!) is export {
        $a does ElementX;
    }

    
    my subset PoA of Attribute where { $_ !~~ NodeX};

    multi sub serialise(Cool $val, ElementX $a) {
        my $x = XML::Element.new(name => $a.xml-name);
        $x.insert(XML::Text.new(text => $val));
        $x;
    }


    multi sub serialise(Cool $val, PoA $a) {
        $val;
    }

    multi sub serialise(XML::Class $val, Attribute $a) {
        $val.to-xml(:element);
    }

    multi method to-xml() returns Str {
        self.to-xml(:document).Str;
    }
    multi method to-xml(:$document!) returns XML::Document {
        my $xe = self.to-xml(:element);
        XML::Document.new($xe);
    }

    multi method to-xml(:$element!) returns XML::Element {
        my $name = $xml-element // self.^name;
        my $xe = XML::Element.new(:$name);
        if $xml-namespace.defined {
            $xe.setNamespace($xml-namespace);
        }
        for self.^attributes -> $attribute {
            my $name =  do given $attribute {
                            when NameX {
                                $attribute.xml-name;
                            }
                            default {
                                $attribute.name.substr(2);
                            }
            }

            my $value = serialise($attribute.get_value(self), $attribute);

            given $value {
                when XML::Element {
                    $xe.insert($value);
                }
                when XML::Text {
                    $xe.insert($name, $value);
                }
                default {
                    $xe.set($name, $value);
                }
            }
        }
        $xe;
    }
}


# vim: expandtab shiftwidth=4 ft=perl6
