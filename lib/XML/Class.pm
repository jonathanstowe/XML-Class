use v6.c;

use XML;

role XML::Class[Str :$xml-namespace, Str :$xml-namespace-prefix, Str :$xml-element] {

    # need to close over these to use within blocks that might have their own defined
    method xml-element {
        $xml-element // $?CLASS.^shortname;
    }
    method xml-namespace {
        $xml-namespace;
    }
    method xml-namespace-prefix {
        $xml-namespace-prefix;
    }

    # Exceptions can be used anywhere here
    my class X::NoElement is Exception {
        has Str $.element is required;
        has Attribute $.attribute is required;
        method message() {
            if $.attribute.defined {
                "Expected element '{ $!element }' not found for attribute '{ $!attribute.name.substr(2) }'";
            }
            else {
                "Expected element '{ $!element }' not found";
            }
        }
    }

    # Roles applied by the traits
    my role NameX {
        has Str $.xml-name is rw;
        method xml-name() is rw returns Str {
            $!xml-name //= $.name.substr(2);
            $!xml-name;
        }
    }

    my role NodeX  {
    }

    my role AttributeX does NodeX does NameX {
    }

    my role ElementX[Bool :$from-serialise] does NodeX does NameX {
        has Bool $.from-serialise = $from-serialise;

    }

    my role ContainerX does NodeX {
        has Str $.container-name is rw;
        method container-name() is rw returns Str {
            $!container-name //= $.name.substr(2);
            $!container-name;
        }

    }

    # This is to provide "simple content" within a complext type
    my role ContentX does NodeX {
    }

    my role NamespaceX[Str :$xml-namespace, Str :$xml-namespace-prefix] does NodeX {
        has Str $.xml-namespace        = $xml-namespace;
        has Str $.xml-namespace-prefix = $xml-namespace-prefix;
    }

    # Just a stub as only used for signalling
    my role SkipNullX does NodeX {
    }

    my role SerialiseX[&serialiser] {
        has &.serialiser = &serialiser;
        method serialise($value) {
            self.serialiser.($value);
        }
    }

    my role DeserialiseX[&deserialiser] {
        has &.deserialiser = &deserialiser;
        method deserialise($value) {
            self.deserialiser.($value);
        }
    }

    # xml-any
    my role AnyX {
    }

    # Dummy class to substitute for the actual type
    # when we have an AnyX
    my class XmlAny {

    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-any!) is export {
        $a does AnyX;
    }

    multi sub trait_mod:<is> (Attribute $a, :&xml-serialise!) is export {
        $a does SerialiseX[&xml-serialise];
    }

    multi sub trait_mod:<is> (Attribute $a, :&xml-deserialise!) is export {
        $a does DeserialiseX[&xml-deserialise];
    }
    multi sub trait_mod:<is> (Attribute $a, :$xml-skip-null!) is export {
        $a does SkipNullX;
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-simple-content!) is export {
        $a does ContentX;
    }

    multi sub trait_mod:<is> (Attribute $a, Str :$xml-namespace) is export {
        $a does NamespaceX[:$xml-namespace];
    }
    multi sub trait_mod:<is> (Attribute $a, :$xml-namespace! (Str $namespace, $namespace-prefix?)) is export {
        $a does NamespaceX[xml-namespace => $namespace, xml-namespace-prefix => $namespace-prefix];
    }

    multi sub trait_mod:<is> (Attribute $a, :$xml-container) is export {
        $a does ContainerX;
        if $xml-container.defined && $xml-container ~~ Str {
            $a.container-name = $xml-container;
        }
    }

    multi sub trait_mod:<is> (Attribute $a, Bool :$xml-attribute!) is export {
        $a does AttributeX;
    }

    multi sub trait_mod:<is> (Attribute $a, Str:D :$xml-attribute!) is export {
        $a does AttributeX;
        $a.xml-name = $xml-attribute;
    }

    multi sub trait_mod:<is> (Attribute $a, Bool :$xml-element!) is export {
        $a does ElementX;
    }
    multi sub trait_mod:<is> (Attribute $a, Str:D :$xml-element!) is export {
        $a does ElementX;
        $a.xml-name = $xml-element;
    }

    sub apply-namespace(Attribute $attribute) {

    }


    my role ElementWrapper {

        has Str $.xml-namespace        is rw;
        has Str $.xml-namespace-prefix is rw;

        method xml-namespace-prefix() is rw {
            if not $!xml-namespace-prefix.defined {
                if not $!xml-namespace.defined {
                    if self.parent.defined {
                        $!xml-namespace-prefix = self.parent.?xml-namespace-prefix;
                    }
                }
            }
            $!xml-namespace-prefix;
        }

        # These are for parsing, the above is for generating
        has Str $.local-name;

        method local-name() {
            if not $!local-name.defined {
                if $.name.index(':') {
                    ( $!prefix, $!local-name) = $.name.split(':', 2);
                }
                else {
                    $!local-name = $.name;
                }
            }
            $!local-name;
        }

        has Str $.prefix;

        # may not be a prefix but will always be a local-name
        method prefix() {
            if not $!local-name.defined {
                my $ = self.local-name;
            }
            $!prefix;
        }


        has Str %.namespaces;

        method local-namespaces() {
            sub map-ns(Pair $p) {
                my $key = do if $p.key.index(':') { 
                        $p.key.split(':')[1] 
                } 
                else { 
                    'default'
                }; 
                $key => $p.value;
            }
            self.attribs.pairs.grep( { $_.key.starts-with('xmlns') }).map(&map-ns).hash;
        }

        method namespaces() {
            if not %!namespaces.keys {
                my %parents;
                if self.parent.defined {
                    if self.parent.can('namespaces') {
                        %parents = self.parent.namespaces;
                    }
                }
                %!namespaces = %parents, self.local-namespaces;
            }
            %!namespaces;
        }

        method namespace() {
            my $prefix = self.prefix // 'default';
            self.namespaces{$prefix};
        }

        method prefix-for-namespace(Str:D $ns) {
            self.namespaces.invert.hash{$ns};
        }

        method add-object-attribute(Mu $val, Attribute $attribute) {
            if $attribute.has_accessor {
                my $name = self.make-name($attribute);
                my $value = $val.defined ?? $attribute.get_value($val) !! $attribute.type;
                if $attribute !~~ SkipNullX || $value.defined {
                    my $values = serialise($value, $attribute);
                    self.add-value($name, $values);
                }
            }
        }

        method add-wrapper(Attribute $a) returns XML::Element {
            my XML::Element $wrapped = self;
            if $a.defined && $a ~~ ElementX && !$a.from-serialise {
                my $t = create-element($a);
                $t.insert(self);
                $wrapped = $t;
            }
            $wrapped;
        }

        method make-name(Attribute $attribute) returns Str {
            my $name =  do given $attribute {
                when NameX {
                    $attribute.xml-name;
                }
                default {
                    $attribute.name.substr(2);
                }
            }
            $name;
        }

        method add-value(Str $name, $values ) {
            for $values.list -> $value {
                given $value {
                    when ElementWrapper {
                        if $!xml-namespace-prefix.defined {
                            $value.xml-namespace-prefix //= $!xml-namespace-prefix;
                        }
                        self.append($value);
                    }
                    when XML::Element {
                        self.append($value);
                    }
                    when XML::Text {
                        self.append($value);
                    }
                    when Pair {
                        self.set($_.key, $_.value);
                    }
                    default {
                        self.set($name, $value);
                    }
                }
            }
        }

        multi sub check-role(Any:U) {
            Nil
        }
        multi sub check-role(ElementWrapper $element) returns ElementWrapper {
            $element;
        }

        multi sub check-role(XML::Element $element where * !~~ ElementWrapper ) returns ElementWrapper {
            if $element !~~ $?ROLE {
                $element does $?ROLE;
            }
            $element
        }

        multi sub check-role(XML::Text $node) {
            $node;
        }

        method first-child() {
            check-role(self.firstChild);
        }

        # better find by namespace
        method find-child(Str $name, Str $ns?) {
            my $element = self.elements(TAG => $name, :SINGLE) || self.elements.map(&check-role).grep({ $_.local-name eq $name && $_.namespace eq $ns}).first;
            check-role($element);
        }

        method find-children(Str $name, Str $ns?) {
            (self.elements(TAG => $name) || self.elements.map(&check-role).grep({ $_.local-name eq $name && $_.namespace eq $ns})).map(&check-role);
        }

        multi method positional-element(Attribute $attribute, Cool $t) {
            check-role(self.firstChild);
        }

        multi method positional-element(Attribute $attribute, Mu $t) {
            check-role( $attribute ~~ ElementX ?? self.firstChild !! self);
        }

        multi method positional-children(Str $name, Attribute $attribute where * !~~ AnyX, Mu $t, Str :$namespace) {
            my @elements;

            for self.find-children($name, $namespace) -> $node {
                @elements.append: $node.positional-element($attribute, $t);
            }
            @elements;
        }

        multi method positional-children(Str $name, AnyX $attribute, Mu $t, Str :$namespace ) {
            my @elements;
            for self.elements.map(&check-role) -> $node {
                @elements.append: $node.positional-element($attribute, $t);
            }
            @elements;
        }

        method strip-wrapper(Attribute $attribute, Str :$namespace is copy) {

            if !$namespace.defined || $attribute ~~ NamespaceX {
                $namespace = $attribute ~~ NamespaceX ?? $attribute.xml-namespace !! self.namespace;
            }
            
            check-role($attribute ~~ ContainerX ?? self.find-child($attribute.container-name, $namespace) !! self);
        }

        method setNamespace($uri, $prefix?) {
            self.XML::Element::setNamespace($uri, $prefix);
            $!xml-namespace = $uri;
            if $prefix.defined {
                $!xml-namespace-prefix = $prefix;
            }
        }

        method name() is rw {
            my $n = self.XML::Element::name();
            if self.xml-namespace-prefix {
                $n = self.xml-namespace-prefix ~ ':' ~ $n;
            }
            $n;
        }
    }

    multi sub create-element(Attribute $a, Bool :$container) returns XML::Element {
        my $name = do if $container {
            $a.container-name;
        }
        else {
            $a ~~ ElementX ?? $a.xml-name !! $a.name.substr(2);
        }
        my $x = do if $a ~~ NamespaceX {
            if $a ~~ ContainerX && !$container {
                create-element($name);
            }
            else {
                create-element($name, $a.xml-namespace, $a.xml-namespace-prefix);
            }
        }
        else {
            create-element($name);
        }
        $x;
    }

    multi sub create-element(Str:D $name, Any:U $?, Any:U $? ) returns XML::Element {
        my $x = XML::Element.new(:$name);
        $x does ElementWrapper;
        $x;
    }

    multi sub create-element(Str:D $name, Str $xml-namespace, $xml-namespace-prefix?) {
        my $xe = samewith($name);
        if $xml-namespace.defined {
            $xe.setNamespace($xml-namespace, $xml-namespace-prefix);
        }
        $xe;
    }

    
    my subset PoA of Attribute where { $_ !~~ NodeX};

    # serialise should have the most specific type
    # first and then call the one with a specific
    # attribute with the string representation

    multi sub serialise($val, SerialiseX $a) {
        my $str = $a.serialise($val);
        serialise($str, $a);
    }

    multi sub serialise(Bool $val, Attribute $a) {
        my $str = $val ?? 'true' !! 'false';
        serialise($str, $a);
    }

    multi sub serialise(Real $val, Attribute $a) {
        my $v = $val.defined ?? $val.Str !! '';
        serialise($v, $a);
    }

    multi sub serialise(DateTime $val, Attribute $a) {
        my $v = $val.defined  ?? $val.Str !! '';
        serialise($v, $a);
    }

    multi sub serialise(Date $val, Attribute $a) {
        my $v = $val.defined  ?? $val.Str !! '';
        serialise($v, $a);
    }

    multi sub serialise(Str $val, ElementX $a) {
        my $x = create-element($a);
        if $val.defined {
            $x.insert(XML::Text.new(text => $val));
        }
        $x;
    }


    # Not sure why this works in some places and not others
    # hence the overly specific param

    my subset NoArray of Cool where * !~~ Positional|Associative;

    multi sub serialise(Str $val, PoA $a) {
        $val // '';
    }

    multi sub serialise(Cool $val, AttributeX $a) {
        ($a.xml-name => $val);
    }

    # One big sub because the multis were getting out of control
    multi sub serialise(@vals, Attribute $a) {
        my @els;
        for @vals.list -> $value {
            # we always want elements so set this but some objects we want the user to choose
            # whether they get the additional container so indicate we added it.
            @els.append: serialise($value, $a ~~ ElementX ?? $a !! $a but ElementX[:from-serialise]);
        }
        if $a ~~ ContainerX {
            my $el = create-element($a, :container);

            for @els -> $item {
                $el.append($item);
            }
            @els = ($el);
        }
        @els;
    }

    # this is simplified because adding them as XML attributes
    # is almost impossible to do in the reverse direction
    multi sub serialise(%vals, Attribute $a) {
        my $els = create-element($a);
        for %vals.kv -> $key, $value {
            $els.insert($key, $value);
        }
        $els;
    }


    multi sub serialise(XML::Class $val, Attribute $a) {
        $val.to-xml(:element, attribute => $a);
    }

    multi sub serialise(Cool $val, ContentX $a) {
        if $val.defined {
            XML::Text.new(text => $val);
        }
        else {
            Nil
        }
    }


    multi sub serialise(Mu $val, Attribute $a, $xml-element?, $xml-namespace?, $xml-namespace-prefix? ) {
        my $name = $xml-element // $val.^shortname;
        my $ret;
        # if it really isn't defined and we don't know what type it is skip it
        if !(!$val.defined && $val.WHAT =:= Any ) {
            my $xe = create-element($name, $xml-namespace, $xml-namespace-prefix);
            for $val.^attributes -> $attribute {
                $xe.add-object-attribute($val, $attribute);
            }
            # Add a wrapper if asked for
            # the from-serialise is true when this was set by default
            # in the Positional serialise.
            $ret = $xe.add-wrapper($a);
        }
        else {
            # however we may want the container nonetheless
            if $a.defined && $a ~~ ElementX && !$a.from-serialise {
                $ret = create-element($a);
            }
        }
        $ret;
    }

    multi method to-xml() returns Str {
        self.to-xml(:document).Str;
    }
    multi method to-xml(:$document!) returns XML::Document {
        my $xe = self.to-xml(:element);
        XML::Document.new($xe);
    }
    multi method to-xml(:$element!, Attribute :$attribute) returns XML::Element {
        serialise(self, $attribute, $xml-element, $xml-namespace, $xml-namespace-prefix);
    }

    multi method from-xml(XML::Class:U: Str $xml) returns XML::Class {
        my $doc = XML::Document.new($xml);
        self.from-xml($doc);
    }

    multi method from-xml(XML::Class:U: XML::Document:D $xml) returns XML::Class {
        my $root = $xml.root;
        self.from-xml($root);
    }

    multi method from-xml(XML::Class:U: XML::Element:D $xml, Attribute :$attribute) returns XML::Class {
        deserialise($xml, $attribute, self, :outer);
    }

    # Helpers should be moved
    multi sub get-positional-name(Attribute $attribute, Cool $t, :$namespace) {
        $attribute ~~ ElementX ?? $attribute.xml-name !! $attribute.name.substr(2);
    }

    multi sub get-positional-name(Attribute $attribute, Mu $t, Str :$namespace) {
        $attribute ~~ ElementX ?? $attribute.xml-name !! $t ~~ XML::Class ?? $t.xml-element !! $t.^shortname;
    }
    # Make sure we have all our helpers
    multi sub deserialise(XML::Element $element where * !~~ ElementWrapper,|c) {
        $element does ElementWrapper;
        deserialise($element, |c);
    }


    # For deserialise the most specific Attribute.type with the least specific type of Attribute
    # for scalar, aggregate types will call deserialise on the parts.
    # They also need to deal with either a Wrapped element or an XML::Text

    my subset TypedNode of XML::Node where * ~~ XML::Text|ElementWrapper;

    # This one implements "custom deserialisation"
    multi sub deserialise(TypedNode $element, DeserialiseX $attribute, $obj, Str :$namespace) {
        my $val = deserialise($element, $attribute, Str, :$namespace);
        $attribute.deserialise($val);
    }

    multi sub deserialise(TypedNode $element, Attribute $attribute, Bool $obj, Str :$namespace) {
        my $val = deserialise($element, $attribute, Str, :$namespace);
        $val.defined ?? ($val eq 'true' || $val eq '1' ) ?? True !! False !! False;
    }

    multi sub deserialise(TypedNode $element, Attribute $attribute, DateTime $obj, Str :$namespace) {
        my $val = deserialise($element, $attribute, Str, :$namespace);
        my DateTime $d = try DateTime.new($val);
        $d;
    }

    multi sub deserialise(TypedNode $element, Attribute $attribute, Date $obj, Str :$namespace) {
        my $val = deserialise($element, $attribute, Str, :$namespace);
        my Date $d = try Date.new($val);
        $d;
    }

    multi sub deserialise(TypedNode $element, Attribute $attribute, Real $obj, Str :$namespace) {
        my $val = deserialise($element, $attribute, Str, :$namespace);
        $val.defined ?? $obj($val) !! $obj;
    }

    multi sub deserialise(ElementWrapper $element, PoA $attribute, Str $obj, Str :$namespace) {
        my $val = $element.attribs{$attribute.name.substr(2)};
        $val;
    }

    multi sub deserialise(ElementWrapper $element, AttributeX $attribute, Str $obj, Str :$namespace) {
        my $val = $element.attribs{$attribute.xml-name};
        $val;
    }

    multi sub deserialise(ElementWrapper $element, ElementX $attribute, XmlAny $obj, Str :$namespace is copy) {
        my $name = $attribute.xml-name;

        if $attribute ~~ NamespaceX {
            $namespace = $attribute.xml-namespace;
        }

        my $node = $element.find-child($name, $namespace);
        my $ret = do if $node.defined {
            my $child = $node.first-child;
            given $child {
                when XML::Text {
                    $child.Str;
                }
                when XML::CDATA {
                    $child.data;
                }
                when XML::Element {
                    if $child.namespace -> $ns {
                        if %*NS-MAP and %*NS-MAP{$ns}:exists {
                            deserialise($child, $attribute, %*NS-MAP{$ns}, namespace => $ns);
                        }
                        else {
                            Nil;
                        }
                    }
                    else {
                        Nil;
                    }
                }
                default {
                    $obj; # the element has no child;
                }
            }
        }
        else {
            $obj;
        }
        $ret;
    }

    multi sub deserialise(ElementWrapper $element, ElementX $attribute, Str $obj, Str :$namespace is copy) {
        my $name = $attribute.xml-name;

        if $attribute ~~ NamespaceX {
            $namespace = $attribute.xml-namespace;
        }

        my $node = $element.find-child($name, $namespace);
        my $ret = do if $node.defined {
            my $child = $node.firstChild;
            given $child {
                when XML::Text {
                    $child.Str;
                }
                when XML::CDATA {
                    $child.data;
                }
                when XML::Element {
                    Nil; # Almost certainly got here because it was an untyped attribute
                }
                default {
                    $obj; # the element has no child;
                }
            }
        }
        else {
            $obj;
        }
        $ret;
    }

    multi sub deserialise(ElementWrapper $element, ContentX $attribute, $obj, Str :$namespace) {
        $element.firstChild.Str;
    }

    multi sub deserialise(XML::Text $text, Attribute $attribute, Str $obj, Str :$namespace) {
        $text.Str;
    }

    multi sub derive-type(Mu $type is raw, ElementWrapper $e, Attribute $a where * !~~ AnyX) {
        $type =:= Mu ?? Str !! $type;
    }

    multi sub derive-type(Mu $type is raw, ElementWrapper $e, AnyX $a) {
        $type =:= Mu ?? XmlAny !! $type;
    }

    multi sub deserialise(ElementWrapper $element, Attribute $attribute, @obj, Str :$namespace is copy) {
        my @vals;
        my $t = derive-type(@obj.of, $element, $attribute);
        my $name = get-positional-name($attribute, $t, :$namespace);
        if not $namespace.defined {
            $namespace = $t ~~ XML::Class ?? $t.xml-namespace !! $element.namespace;
        }
        my $e = $element.strip-wrapper($attribute, :$namespace);

        if $e.defined {
            $namespace = $t ~~ XML::Class ?? $t.xml-namespace !! $attribute ~~ NamespaceX ?? $attribute.xml-namespace !! $e.namespace;
            for $e.positional-children($name, $attribute, $t, :$namespace) -> $node {
                if $t ~~ XmlAny {
                    if $node.namespace -> $ns {
                        if %*NS-MAP and %*NS-MAP{$ns}:exists {
                            @vals.append: deserialise($node, $attribute, %*NS-MAP{$ns}, namespace => $ns);
                        }
                    }
                }
                else {
                    @vals.append:  deserialise($node, $attribute, $t, :$namespace);
                }
            }
        }
        @vals;
    }

    multi sub deserialise(ElementWrapper $element, Attribute $attribute, Cool %obj, Str :$namespace) {
        my %vals;

        if $attribute ~~ ElementX {
            my $name = $attribute.xml-name;
            my $c = $element.elements(TAG => $name, :SINGLE);
            for $c.nodes -> $node {
                %vals{$node.name} = deserialise($node.firstChild, $attribute, %obj.of, :$namespace);
            }
        }
        else {
            warn "Unable to deserialise this Hash from XML";
        }
        %vals;
    }


    multi sub deserialise(ElementWrapper $element is copy, Attribute $attribute, Mu $obj, Str :$namespace, Bool :$outer) {

        my $name = $obj ~~ XML::Class ?? $obj.xml-element !! $obj.^shortname;

        my Str $ns = $obj ~~ XML::Class ?? $obj.xml-namespace // $namespace !! $namespace;

        if $ns {
            my $prefix = $element.prefix-for-namespace($ns);
            if $prefix  && $prefix ne 'default' {
                $name = "$prefix:$name";
            }
        }


        if $attribute ~~ ElementX and $element.name ne $name {
            my $name = $attribute.xml-name;
            $element = $element.find-child($name, $ns);
            if !$element && $outer {
                X::NoElement.new(element => $name, attribute => $attribute).throw
            }
        }
        if $element.defined and $element.name ne $name {
            $element = $element.find-child($name, $ns);
            if !$element && $outer {
                X::NoElement.new(element => $name, attribute => $attribute).throw
            }
        }


        my $ret = $obj;
        if $element {
            my %args;
            for $obj.^attributes -> $attr {
                my $attr-name = $attr.name.substr(2);
                my $type = derive-type($attr.type, $element, $attr);
                %args{$attr-name} := deserialise($element, $attr, $type, namespace => $ns);
            }
            $ret = $obj.new(|%args);
        }
        $ret;
    }
}

# vim: expandtab shiftwidth=4 ft=perl6
