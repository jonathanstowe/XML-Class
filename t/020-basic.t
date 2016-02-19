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

class Foo::Bar does XML::Class {
    has Int $.version = 0;
    has Str $.zub is xml-element;
}


$f = Foo::Bar.new(zub => "pow");
lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class no over0rides";
isa-ok $xml, XML::Document, "and it is an XML::Document";
is $xml.root.name, 'Bar', "and we appear to have the right root node";

diag $xml;

class Zub does XML::Class {
    has Str @.things;
}

$f = Zub.new(things => <a b c d>);

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has positional attribute no over-rides";

is $xml.root.nodes.elems, 4, "should have four child elements";
for $xml.root.nodes -> $el {
    isa-ok $el, XML::Element, "and elements";
    is $el.name, 'things', "and the right name";
}

diag $xml;

class Bub does XML::Class {
    has Str @.things is xml-element('thing');
}

$f = Bub.new(things => <a b c d>);

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has positional attribute over-ride on item";

is $xml.root.nodes.elems, 4, "should have four child elements";
for $xml.root.nodes -> $el {
    isa-ok $el, XML::Element, "and elements";
    is $el.name, 'thing', "and the right name";
}
diag $xml;

class Rub does XML::Class {
    has Str @.things is xml-container is xml-element('thing');
}

$f = Rub.new(things => <a b c d>);

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has positional attribute over-ride on item and container";

is $xml.root.nodes.elems, 1, "should have four child elements";
is $xml.root[0].name, 'things', "got container";
is $xml.root[0].nodes.elems, 4, "and that has four children";
for $xml.root[0].nodes -> $el {
    isa-ok $el, XML::Element, "and elements";
    is $el.name, 'thing', "and the right name";
}

diag $xml;

class Dub does XML::Class {
    has Str @.things is xml-container('burble') is xml-element('thing');
}

$f = Dub.new(things => <a b c d>);

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has positional attribute over-ride on item and container with name";

is $xml.root.nodes.elems, 1, "should have four child elements";
is $xml.root[0].name, 'burble', "got container with the explicitly set name";
is $xml.root[0].nodes.elems, 4, "and that has four children";
for $xml.root[0].nodes -> $el {
    isa-ok $el, XML::Element, "and elements";
    is $el.name, 'thing', "and the right name";
}

diag $xml;

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
