USING: help.markup help.syntax io io.streams.null quotations ;
IN: io.streams.null+docs

HELP: null-reader
{ $class-description "Singleton class of null reader streams." } ;

HELP: null-writer
{ $class-description "Singleton class of null writer streams." } ;

HELP: with-null-reader
{ $values { "quot" quotation } }
{ $description "Calls the quotation with " { $link input-stream } " rebound to a " { $link null-reader } " which always produces EOF." } ;

HELP: with-null-writer
{ $values { "quot" quotation } }
{ $description "Calls the quotation with " { $link output-stream } " rebound to a " { $link null-writer } " which ignores all output." } ;

ARTICLE: "io.streams.null" "Null streams"
"The " { $vocab-link "io.streams.null" } " vocabulary implements a pair of streams which are useful for testing. The null reader always yields EOF and the null writer ignores all output. Conceptually, they are similar to " { $snippet "/dev/null" } " on a Unix system."
$nl
"Null readers:"
{ $subsections
    null-reader
    with-null-writer
}
"Null writers:"
{ $subsections
    null-writer
    with-null-reader
} ;

ABOUT: "io.streams.null"
