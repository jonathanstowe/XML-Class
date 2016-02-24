#!perl6

use v6;

use Test;

my Bool $DEBUG = True;

use XML::Class;

class Inner does XML::Class[xml-namespace => 'http://example.com/inner', xml-namespace-prefix => 'in'] {
    has Str $.string is xml-element;
}

class Named does XML::Class[xml-namespace => 'http://example.com/named', xml-namespace-prefix => 'nx'] {
    has Inner $.inner;
    has Str   $.string is xml-element;
}

my $obj = Named.new(string => 'thing', inner => Inner.new(string => 'inner-thing'));
my $in;
lives-ok { $in = $obj.to-xml(:document); }, "to-xml() with namespace and inner class with namespace";

diag $in if $DEBUG;

my $out;

lives-ok { $out = Named.from-xml($in);  }, "from-xml with prefixed namespaces";

isa-ok $out, Named, "got the right thing";
isa-ok $out.inner, Inner, "and the inner class";
is $out.string, $obj.string, "outer string is right";
is $out.inner.string, $obj.inner.string, "inner string is right";

class NamedWithPositional does XML::Class[xml-namespace => 'http://example.com/named', xml-namespace-prefix => 'nx'] {
    has Inner @.inners is xml-container('Body');
    has Str   $.string is xml-element;
}

$obj = NamedWithPositional.new(string => 'thing', inners => (Inner.new(string => 'inner-thing'), Inner.new(string => 'other-thing')));
lives-ok { $in = $obj.to-xml(); }, "to-xml() with namespace and array of inner class with namespace";

diag $in if $DEBUG;


lives-ok { 
$out = NamedWithPositional.from-xml($in);   }, "from-xml with prefixed namespaces and array inner class with namespace";

isa-ok $out, NamedWithPositional, "got the right thing";
is $out.string, $obj.string, "outer string is right";
diag $out.to-xml();

ok $out.inners.elems, "got the inner items";
for ^$out.inners.elems -> $i {
    isa-ok $out.inners[$i], Inner, "and the inner class";
    is $out.inners[$i].string, $obj.inners[$i].string, "inner string is right";
}

done-testing;

# vim: expandtab shiftwidth=4 ft=perl6
