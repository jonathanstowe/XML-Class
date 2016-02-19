# XML::Class

Role to Serialize/De-Serialize a Perl 6 class to/from XML

## Synopsis

```

use XML::Class;

class Foo does XML::Class[xml-element => 'foo'] {
    has Int $.version = 0;
    has Str $.zub is xml-element;
}

my $f = Foo.new(zub => "pow");

say $f.to-xml; # <?xml version="1.0"?><foo xmlns="http://example.com/" version="0"><zub>pow</zub></foo>


```


## Description

This provides a relatively easy way to instantiate a Perl 6 object from XML and create XML
that describes the Perl 6 class in a consistent manner.

It is somewhat inspired by the XmlSerialization class of the .Net framework, but there are
other antecedents.

Using a relatively static definition of the relation between a class and XML that represents
it means that XML can be consistently parsed and generated in a way that should always
remain valid to the original description.


