#!perl6

use v6;

use Test;

my Bool $DEBUG = True;

use XML::Class;

class Named does XML::Class[xml-namespace => 'http://example.com/named', xml-namespace-prefix => 'nx'] {
    class Inner does XML::Class[xml-namespace => 'http://example.com/inner', xml-namespace-prefix => 'in'] {
        has Str $.string is xml-element;

    }
    has Inner $.inner;
    has Str   $.string is xml-element;
}

my $obj = Named.new(string => 'thing', inner => Named::Inner.new(string => 'inner-thing'));

my $in;

lives-ok { $in = $obj.to-xml(:document); }, "to-xml() with namespace and inner class with namespace";



diag $in if $DEBUG;

my $out;

lives-ok { $out = Named.from-xml($in);  }, "from-xml with prefixed namespaces";

isa-ok $out, Named, "got the right thing";
isa-ok $out.inner, Named::Inner, "and the inner class";
is $out.string, $obj.string, "outer string is right";
is $out.inner.string, $obj.inner.string, "inner string is right";

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
