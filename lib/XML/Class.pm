use v6.c;

use XML;

role XML::Class[Str :$xml-namespace, Str :$xml-element] {
    my role Name {
        has Str $.xml-name;
    }

    my role AttributeX does Name {
    }

    my role ElementX does Name {

    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-attribute!) is export {
        $a does AttributeX;
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-element!) is export {
        $a does ElementX;
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
            my $name =  $attribute.name.substr(2);
            given $attribute {
                when ElementX {
                    $xe.insert($name, $attribute.get_value(self));
                }
                default {
                    $xe.set($name, $attribute.get_value(self));
                }
            }
        }
        $xe;
    }
}


# vim: expandtab shiftwidth=4 ft=perl6
