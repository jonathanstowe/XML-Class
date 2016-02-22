#!perl6

use v6;

use Test;

use XML::Class;

my $DEBUG = True;

class SimpleClass does XML::Class {
    has Int $.version;
    has Str $.thing is xml-element;

}

my $obj = SimpleClass.new(version => 0, thing => 'boom');

my $xml =  $obj.to-xml;

diag $xml if $DEBUG;

my $out;

lives-ok { $out = SimpleClass.from-xml($xml); }, "from-xml(Str)";

isa-ok $out, SimpleClass, "got back the class we expected";

is $out.version, $obj.version, "got the version we expected";
is $out.thing, $obj.thing, "and the element attribute";




done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
