#!perl6

use v6;

use Test;

my Bool $DEBUG;

use XML::Class;

class Empty does XML::Class {
}

lives-ok {
    my $x = Empty.new.to-xml;
    diag $x if $DEBUG;
}, "empty class (to-xml)";

class Missing does XML::Class {
    has Str $.empty is xml-element;
}

lives-ok {
    my $x = Missing.new.to-xml;
    diag $x if $DEBUG;
}, "class with un-initialised xml-element attribute (to-xml)";

class MissingAttribute does XML::Class {
    has Str $.empty;
}

lives-ok {
    CONTROL {
        when CX::Warn {
            die "got a warning $_";
        }
    }
    my $x = MissingAttribute.new.to-xml;
    diag $x if $DEBUG;
}, "class with un-initialised attribute (to-xml)";

class EmptyArray does XML::Class {
    has Str @.empty;
}

lives-ok {
    my $x = EmptyArray.new.to-xml;
    diag $x if $DEBUG;
}, "class with un-initialised positional attribute (to-xml)";

lives-ok {
    my $x = EmptyArray.new.to-xml;
    diag $x if $DEBUG;
    my $y = EmptyArray.from-xml($x);
}, "class with un-initialised positional attribute (from-xml)";

class EmptyContainer does XML::Class {
    has Str @.empty is xml-container('Empty');
}

lives-ok {
    my $x = EmptyContainer.new.to-xml;
    diag $x if $DEBUG;
}, "class with un-initialised positional attribute with container(to-xml)";

lives-ok {
    my $x = EmptyContainer.new.to-xml;
    diag $x if $DEBUG;
    my $y = EmptyContainer.from-xml($x);
}, "class with un-initialised positional attribute with container (from-xml)";
lives-ok {
    my $y = EmptyContainer.from-xml('<?xml version="1.0"?><EmptyContainer />');
}, "class with un-initialised positional attribute with container container missing (from-xml)";

class MissingObject does XML::Class {
    class Inner {
        has Str $.str is xml-element;
    }
    has Inner $.inner;
}

lives-ok {
    my $x = MissingObject.new.to-xml;
    diag $x if $DEBUG;
}, "class with object typed attribute uninitialised (to-xml)";

lives-ok {
    my $y = MissingObject.from-xml('<?xml version="1.0"?><MissingObject><Inner><str/></Inner></MissingObject>');
}, "class with object typed attribute uninitialised (from-xml)";
lives-ok {
    my $y = MissingObject.from-xml('<?xml version="1.0"?><MissingObject><Inner /></MissingObject>');
}, "class with object typed attribute uninitialised no empty attribute (from-xml)";
lives-ok {
    my $y = MissingObject.from-xml('<?xml version="1.0"?><MissingObject />');
}, "class with object typed attribute uninitialised no class outer element (from-xml)";
throws-like {
    my $y = MissingObject.from-xml('<?xml version="1.0"?><MissingFoo />');
}, X::NoElement, message => "Expected element 'MissingObject' not found", "missing matching outer element (from-xml)";

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
