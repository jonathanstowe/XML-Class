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
is $xml.Str, '<?xml version="1.0"?><foo xmlns="http://example.com/" version="0"><zub>pow</zub></foo>', 'looks fine';

diag $xml;

class Foo::Bar does XML::Class {
    has Int $.version = 0;
    has Str $.zub is xml-element;
}


$f = Foo::Bar.new(zub => "pow");
lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class no over0rides";
isa-ok $xml, XML::Document, "and it is an XML::Document";
is $xml.root.name, 'Bar', "and we appear to have the right root node";
is $xml.Str, '<?xml version="1.0"?><Bar version="0"><zub>pow</zub></Bar>', 'looks good';
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
is $xml.Str, '<?xml version="1.0"?><Zub><things>d</things><things>c</things><things>b</things><things>a</things></Zub>', 'looks good';
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
is $xml.Str, '<?xml version="1.0"?><Bub><thing>d</thing><thing>c</thing><thing>b</thing><thing>a</thing></Bub>', 'looks good';
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
is $xml.Str, '<?xml version="1.0"?><Rub><things><thing>d</thing><thing>c</thing><thing>b</thing><thing>a</thing></things></Rub>', 'looks good';
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
is $xml.Str, '<?xml version="1.0"?><Dub><burble><thing>d</thing><thing>c</thing><thing>b</thing><thing>a</thing></burble></Dub>','looks good';
diag $xml;

class Hup does XML::Class {
    has Str %.things;
}

$f = Hup.new(things => (a => 'A', b => 'B', c => 'C', d => 'D'));
lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has Associative attribute with plain values";
is $xml.root.attribs.keys.elems, 4, "and have four attributes in the root";
is $xml.Str, '<?xml version="1.0"?><Hup a="A" d="D" c="C" b="B"/>', 'looks good';
diag $xml;

class Hut does XML::Class {
    has Str %.things is xml-element;
}

$f = Hut.new(things => (a => 'A', b => 'B', c => 'C', d => 'D'));
lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has Associative attribute with plain values";
is $xml.root.nodes.elems, 1, "and have there 1 elements in the root";
is $xml.root[0].name, 'things', "and it has the top-level name";
is $xml.root[0].nodes.elems, 4, "and there are child elements";
is $xml.Str, '<?xml version="1.0"?><Hut><things><b>B</b><c>C</c><d>D</d><a>A</a></things></Hut>', 'looks good';
diag $xml;

class Zut does XML::Class {
    class Vub {
        has Str $.thing;
    }

    has Vub $.vub;

}

$f = Zut.new(vub => Zut::Vub.new(thing => "boom"));

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has Object attribute";
is $xml.root.nodes.elems, 1, "and have there 1 elements in the root";
is $xml.root[0].name, 'Vub', "and it has the top-level name";
is $xml.root[0]<thing>, "boom", "and it has the attribute we expected";
is $xml.Str,'<?xml version="1.0"?><Zut><Vub thing="boom"/></Zut>', 'looks good';
diag $xml;

class Zuz does XML::Class {
    class Vub {
        has Str $.thing is xml-element;
    }

    has Vub $.vub is xml-element('Body');

}

$f = Zuz.new(vub => Zuz::Vub.new(thing => "boom"));

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has Object attribute but with xml-element";
is $xml.root.nodes.elems, 1, "and have there 1 elements in the root";
is $xml.root[0].name, 'Body', "and it has the top-level name";
is $xml.root[0][0].name, "Vub", "and it has the child we expected";
is $xml.root[0][0][0].name, 'thing', "and that has the child we expected";
is $xml.Str, '<?xml version="1.0"?><Zuz><Body><Vub><thing>boom</thing></Vub></Body></Zuz>', 'looks good';
diag $xml;

class Zug does XML::Class {
    class Vub does XML::Class[xml-element => 'Stuff', xml-namespace => 'urn:example'] {
        has Str $.thing is xml-element;
    }

    has Vub $.vub is xml-element('Body');

}

$f = Zug.new(vub => Zug::Vub.new(thing => "boom"));

lives-ok { $xml = $f.to-xml(:document);  }, "to-xml(:document) -class has XML::Class attribute but with xml-element";
is $xml.root.nodes.elems, 1, "and have there 1 elements in the root";
is $xml.root[0].name, 'Body', "and it has the top-level name";
is $xml.root[0][0].name, "Stuff", "and it has the child we expected";
is $xml.root[0][0].nsURI, "urn:example", "and it has the namespace we expected";
is $xml.root[0][0][0].name, 'thing', "and that has the child we expected";
is $xml.Str, '<?xml version="1.0"?><Zug><Body><Stuff xmlns="urn:example"><thing>boom</thing></Stuff></Body></Zug>', 'looks good';
diag $xml;

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
