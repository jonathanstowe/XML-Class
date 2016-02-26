#!perl6

use v6;

use Test;
use XML::Class;

my Bool $DEBUG = True;

class Payload does XML::Class[xml-namespace => 'urn:example.com/payload'] {
    has Str $.string is xml-element;

}

class Container is XML::Class {
    has $.head is xml-element('Head');
    has $.body is xml-element('Body') is xml-any;
}

my $obj = Container.new(body => Payload.new(string => 'something'));

my $out;

lives-ok {
    $out = $obj.to-xml;
    diag $out if $DEBUG;
}, "to-xml for thing with xml-any in it";



done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
