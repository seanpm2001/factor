USING: help.markup help.syntax io.encodings.utf16n ;
IN: io.encodings.utf16n+docs

HELP: utf16n
{ $class-description "The encoding descriptor for UTF-16 without a byte order mark in native endian order. This is useful mostly for FFI calls which take input of strings of the type wchar_t*" }
{ $see-also "encodings-introduction" } ;
