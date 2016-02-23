#!perl6

use v6;

use Test;

use XML::Class;

my Bool $DEBUG;

# round trip tests for complex type
# with simple content


class Container does XML::Class {
    class Simple {
        has Str $.lang;
        has Str $.name is xml-simple-content;
    }

    has Simple $.name;
}

my $obj = Container.new(name => Container::Simple.new(lang => 'en', name => 'Something'));
my $in;

lives-ok { $in = $obj.to-xml(:document);  }, "complex type with simple content and attribute"; 
is $in.root.name, 'Container', "got the right root";
is $in.root.nodes.elems, 1, "only got the one child";
is $in.root.nodes[0].name, 'Simple', "and this is what we expected";
is $in.root.nodes[0].attribs.keys.elems, 1, "and only one attribute";
is $in.root.nodes[0].attribs<lang>, $obj.name.lang, "and it's the right value";
isa-ok $in.root.nodes[0].firstChild, XML::Text, "and we got a text";
is $in.root.nodes[0].firstChild.text, $obj.name.name, "and the text is right too";

diag $in if $DEBUG;

my $out;

lives-ok { $out = Container.from-xml($in);  }, "from-xml with complext type with simple content and attribute";
isa-ok $out, Container, "got the right thing back";
isa-ok $out.name, Container::Simple, "and so is the inner class";
is $out.name.name, $obj.name.name, "and the 'name' is right";
is $out.name.lang, $obj.name.lang, "and so is the 'attribute'";


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
