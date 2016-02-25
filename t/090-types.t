#!perl6

use v6;

use Test;
use XML::Class;

my Bool $DEBUG = True;

class Test::Bool does XML::Class {
    has Bool $.attribute;
    has Bool $.element is xml-element;
}

my $obj = Test::Bool.new(attribute => True, element => True);

my $out;

lives-ok { 
    $out = $obj.to-xml(:element);
}, "boolean types - true values to xml";

diag $out if $DEBUG;

is $out<attribute>, 'true', "representation value of attribute is correct";
is $out[0][0].text, 'true', 'representation value of element is correct';

my $in;

lives-ok {
    $in = Test::Bool.from-xml($out);
}, "boolean types - true values to xml";

# these will almost certainly pass in the true case
# irrespective of the actual values
is $in.attribute, $obj.attribute, "attribute values match";
is $in.element, $obj.element, "element values match";

$obj = Test::Bool.new(attribute => False, element => False);


lives-ok { 
    $out = $obj.to-xml(:element);
}, "boolean types - false values to xml";

diag $out if $DEBUG;

is $out<attribute>, 'false', "representation value of attribute is correct";
is $out[0][0].text, 'false', 'representation value of element is correct';

lives-ok {
    $in = Test::Bool.from-xml($out);
}, "boolean types - false values from xml";

# these will almost certainly pass in the true case
# irrespective of the actual values
is $in.attribute, $obj.attribute, "attribute values match";
is $in.element, $obj.element, "element values match";

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
