#!/usr/bin/env raku

use Test;
use XML::Class;

use lib $*PROGRAM.parent.add('lib').Str;

use Region;

my Str $expect1 = '<?xml version="1.0"?><regionInfo><item><regionName>regionName</regionName><regionEndpoint>regionEndpoint</regionEndpoint></item></regionInfo>';

class RegionInfo does XML::Class[xml-element => 'regionInfo'] {
  has Region @.items is xml-element('item', :over-ride);
}

my $ri = RegionInfo.new(items => [ Region.new(regionName => 'regionName', regionEndpoint => 'regionEndpoint') ]);

my $xml = $ri.to-xml;

is $xml, $expect1, 'positional over-ride of class applied';


my $ri2 = RegionInfo.from-xml($xml);

is $ri2.to-xml, $expect1, 'positional over-ride round trips properly';

class InstanceState does XML::Class {
  has Int $.code is xml-element;
  has Str $.name is xml-element;
}
class InstancesStateChange does XML::Class[xml-element => 'item'] {
  has Str           $.instanceID    is xml-element;
  has InstanceState $.currentState  is xml-element(:over-ride);
  has InstanceState $.previousState is xml-element(:over-ride);
}

my $isc = InstancesStateChange.new( instanceID => "foo", currentState => InstanceState.new(code => 10, name => "ten"), previousState => InstanceState.new(code => 20, name => "twenty"));

my $expect2 = '<?xml version="1.0"?><item><instanceID>foo</instanceID><currentState><code>10</code><name>ten</name></currentState><previousState><code>20</code><name>twenty</name></previousState></item>';

$xml = $isc.to-xml;

is $xml, $expect2, 'claas typed scalars with over-ride';


$isc = InstancesStateChange.from-xml($xml);

is $isc.to-xml, $expect2,'claas typed scalars with over-ride round trip';

done-testing;

# vim: ft=raku
