#!perl6

use v6;

use Test;

use XML::Class;

class NSClass does XML::Class[xml-namespace => 'urn:example.com', xml-namespace-prefix => 'nsc'] {
    has Str $.thing is xml-element = "boom";
}

my $xml;
my $obj = NSClass.new;

lives-ok { $xml = $obj.to-xml(:document) }, "to-xml with xml-namespace-prefix";
ok $xml.root.attribs<xmlns:nsc>:exists, "and the namespace declaration has the prefix";
is $xml.root.name, 'nsc:NSClass', 'and the element does have the prefix';
is $xml.root[0].name, 'nsc:thing', "and so does the child element";

diag $xml;


done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
