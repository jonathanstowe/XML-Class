use XML::Class;

class Region does XML::Class is export {
  has Str $.regionName     is xml-element;
  has Str $.regionEndpoint is xml-element;
}

# vim: ft=perl6
