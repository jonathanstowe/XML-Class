#!raku

use v6;

use Test;

use XML::Class;

my Bool $DEBUG;

class SkipTest does XML::Class {
    has Str $.skip-string-element is xml-element is xml-skip-null;
    has Str $.always-string-element is xml-element;
    has Str $.skip-string-attribute is xml-skip-null;
    has Str $.always-string-attribute;
    has Str $.never-string-attribute is xml-skip = "zuuub";
    class Inner {
        has Str $.inner-string is xml-element;
    }

    has Inner $.skip-inner-object is xml-skip-null is xml-element;
    has Inner $.always-inner-object is xml-element;
}

my $xml = SkipTest.new.to-xml(:element);

diag $xml if $DEBUG;

nok $xml.elements(TAG => 'skip-string-element'), "haven't got the one with xml-skip-null";
ok $xml.elements(TAG => "always-string-element"), "but still have the one without it";
nok $xml.attribs<skip-string-attribute>:exists, "haven't got attribute with skip";
nok $xml.attribs<never-string-attribute>:exists, "haven't got defined attribute with xml-skip";
ok  $xml.attribs<always-string-attribute>:exists, "but still have attribute without";
nok $xml.elements(TAG => 'skip-inner-object'), "haven't got object wrapper with skip";
ok  $xml.elements(TAG => 'always-inner-object'), "but still have element without";


done-testing;
# vim: expandtab shiftwidth=4 ft=raku
