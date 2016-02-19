#!perl6

use v6.c;
use Test;

use XML::Class;

class Foo does XML::Class[xml-element => 'foo', xml-namespace => 'http://example.com/'] {
    has Int $.version = 0;
    has Str $.zub is xml-element;
}

my $f = Foo.new(zub => "pow");

my $xml;

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document)";
isa-ok $xml, XML::Document, "and it is an XML::Document";
is $xml.root.name, 'foo', "and we appear to have the right root node";
is $xml.root<version>, 0, "got an attribute 'version'";
is $xml.root.elems, 1, "got one child node";
isa-ok $xml.root[0], XML::Element, "and it actually is an element";
is $xml.root[0].name, "zub", "and it's the one we like";
is $xml.root.nsURI, 'http://example.com/', 'and it has the right xmlns URI';

diag $xml;



done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
