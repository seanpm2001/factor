! Copyright (C) 2004, 2005 Slava Pestov.
! See http://factor.sf.net/license.txt for BSD license.

! Bootstrapping trick; see doc/bootstrap.txt.
IN: !syntax
USING: alien errors generic hashtables kernel lists math
namespaces parser sequences strings syntax unparse vectors
words ;

: parsing ( -- )
    #! Mark the most recently defined word to execute at parse
    #! time, rather than run time. The word can use 'scan' to
    #! read ahead in the input stream.
    word t "parsing" set-word-prop ; parsing

: inline ( -- )
    #! Mark the last word to be inlined.
    word  t "inline" set-word-prop ; parsing

! The variable "in-definition" is set inside a : ... ;.
! ( and #! then add "stack-effect" and "documentation"
! properties to the current word if it is set.

! Booleans

! The canonical t is a heap-allocated dummy object.
BUILTIN: t 7 t? ;
: t t swons ; parsing

! In the runtime, the canonical f is represented as a null
! pointer with tag 3. So
! f address . ==> 3
BUILTIN: f 9 not ;
: f f swons ; parsing

! Lists
: [ f ; parsing
: ] reverse swons ; parsing

! Conses (whose cdr might not be a list)
: [[ f ; parsing
: ]] 2unlist swons swons ; parsing

! Vectors
: { f ; parsing
: } reverse >vector swons ; parsing

! Hashtables
: {{ f ; parsing
: }} alist>hash swons ; parsing

! Tuples.
: << f ; parsing
: >> reverse literal-tuple swons ; parsing

! Do not execute parsing word
: POSTPONE: ( -- ) scan-word swons ; parsing

! Word definitions
: :
    #! Begin a word definition. Word name follows.
    CREATE [ define-compound ] [ ] "in-definition" on ; parsing

: ;
    #! End a word definition.
    "in-definition" off reverse swap call ; parsing

! Symbols
: SYMBOL:
    #! A symbol is a word that pushes itself when executed.
    CREATE define-symbol ; parsing

: \
    #! Parsed as a piece of code that pushes a word on the stack
    #! \ foo ==> [ foo ] car
    scan-word unit swons  \ car swons ; parsing

! Vocabularies
: PRIMITIVE:
    #! This is just for show. All flash no substance.
    "You cannot define primitives in Factor" throw ; parsing

: DEFER:
    #! Create a word with no definition. Used for mutually
    #! recursive words.
    CREATE drop ; parsing

: FORGET:
    #! Followed by a word name. The word is removed from its
    #! vocabulary. Note that specifying an undefined word is a
    #! no-op.
    scan "use" get search [ forget ] when* ; parsing

: USE:
    #! Add vocabulary to search path.
    scan use+ ; parsing

: USING:
    #! A list of vocabularies terminated with ;
    string-mode on
    [ string-mode off [ use+ ] each ]
    f ; parsing

: IN:
    #! Set vocabulary for new definitions.
    scan dup use+ "in" set ; parsing

! Char literal
: CHAR: ( -- ) 0 scan next-char drop swons ; parsing

! String literal
: (parse-string) ( n str -- n )
    2dup nth CHAR: " = [
        drop 1 +
    ] [
        [ next-char swap , ] keep (parse-string)
    ] ifte ;

: parse-string ( -- str )
    #! Read a string from the input stream, until it is
    #! terminated by a ".
    "col" [
        [ "line" get (parse-string) ] make-string swap
    ] change ;

: " parse-string swons ; parsing

: SBUF" skip-blank parse-string >sbuf swons ; parsing

! Comments
: (
    #! Stack comment.
    ")" until parsed-stack-effect ; parsing

: !
    #! EOL comment.
    until-eol drop ; parsing

: #!
    #! Documentation comment.
    until-eol parsed-documentation ; parsing
