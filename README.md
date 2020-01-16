# XML::Class

Role to Serialize/De-Serialize a Raku class to/from XML

[![Build Status](https://travis-ci.org/jonathanstowe/XML-Class.svg?branch=master)](https://travis-ci.org/jonathanstowe/XML-Class)

## Synopsis

```perl6

use XML::Class;

class Foo does XML::Class[xml-element => 'foo', xml-namespace => "http://example.com/"] {
    has Int $.version = 0;
    has Str $.zub is xml-element;
}

my $f = Foo.new(zub => "pow");

say $f.to-xml; # <?xml version="1.0"?><foo xmlns="http://example.com/" version="0"><zub>pow</zub></foo>


```


## Description

This provides a relatively easy way to instantiate a Raku object from
XML and create XML that describes the Raku class in a consistent manner.

It is somewhat inspired by the XmlSerialization class of the .Net
framework, but there are other antecedents.

Using a relatively static definition of the relation between a class
and XML that represents it means that XML can be consistently parsed
and generated in a way that should always remain valid to the original
description.

This module aims to map between Raku object attributes and XML by
providing some default behaviours and some attribute traits to alter
that behaviour to model the XML.

By default scalar attributes whose value type can be expressed as an XML
simple type (e.g.  strings, real numbers, boolean, datetimes) will be
serialised as attribute values or (with an ```xml-element``` trait,)
as elements with simple content.  Positional attributes will always
be serialised as a sequence of elements (with an optional container
specified by a trait,) likewise associative attributes (though the use
of these is discouraged as there is no constraint on the names of the
elements which are taken from the keys of the Hash.)  Raku classes are
expressed as XML complex types with the same serialisation as above.
Provision is also made for the serialisation and de-serialisation of
other than the builtin types to simple contemt (trivial examples might
be Version objects for instance,) and for the handling of data that
might be unknown at definition time (such as the xsd:Any in SOAP head
and body elements,) by the use of "namespace maps".

There are things that explicitly aren't catered for such as  "mixed
content" (that is where XML markup may be within text content as in
XHTML for example,) but that shouldn't be a problem for data storage or
messaging applications for the most part.

The full documentation is available as POD or as
[Markdown](Documentation.md)

## Installation

Assuming you have a working Rakudo installation you should be able to
install this with *zef* :

    # From the source directory
   
    zef install .

    # Remote installation

    zef install XML::Class

Other install mechanisms may be become available in the future.

## Support

Although there are quite a few tests for this I'm sure they don't
cover all the possible cases. So if you find something that isn't
tested for and doesn't work quite as expected please let me know.


Suggestions/patches are welcomed via [github](https://github.com/jonathanstowe/XML-Class)

## Licence

This is free software.

Please see the [LICENCE](LICENCE) file in the distribution

© Jonathan Stowe 2016 - 2020
