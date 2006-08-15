! Copyright (C) 2005, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
IN: words
USING: arrays definitions hashtables help inspector io kernel
math namespaces prettyprint sequences strings styles ;

: word-outliner ( word quot -- )
    swap natural-sort [
        dup rot curry >r [ synopsis ] keep r>
        write-outliner terpri
    ] each-with ;

: usage. ( word -- )
    usage [ usage. ] word-outliner ;

: annotate ( word quot -- )
    over >r >r dup word-def r> call r> swap define-compound ;
    inline

: watch-msg ( word prefix -- ) write word-name print .s flush ;

: (watch) ( word def -- def )
    [
        swap literalize
        dup , "===> Entering: " , \ watch-msg ,
        swap %
        , "===> Leaving:  " , \ watch-msg ,
    ] [ ] make ;

: watch ( word -- ) [ (watch) ] annotate ;

: profile ( word -- )
    [
        swap [ global [ inc ] bind ] curry swap append
    ] annotate ;

: fuzzy ( full short -- indices )
    0 swap >array [ swap pick index* [ 1+ ] keep ] map 2nip
    -1 over member? [ drop f ] when ;

: (runs) ( n i seq -- )
    2dup length < [
        3dup nth [
            number= [
                >r >r 1+ r> r>
            ] [
                split-next,
                rot drop [ nth 1+ ] 2keep
            ] if >r 1+ r>
        ] keep split, (runs)
    ] [
        3drop
    ] if ;

: runs ( seq -- seq )
    [
        split-next,
        dup first 0 rot (runs)
    ] { } make ;

: score-1 ( i full -- n )
    {
        { [ over zero? ] [ 2drop 10 ] }
        { [ 2dup length 1- = ] [ 2drop 4 ] }
        { [ 2dup >r 1- r> nth Letter? not ] [ 2drop 10 ] }
        { [ 2dup >r 1+ r> nth Letter? not ] [ 2drop 4 ] }
        { [ t ] [ 2drop 1 ] }
    } cond ;

: score ( full fuzzy -- n )
    dup [
        [ [ length ] 2apply - 15 swap [-] 3 / ] 2keep
        runs [
            [ swap score-1 ] map-with dup supremum swap length *
        ] map-with sum +
    ] [
        2drop 0
    ] if ;

: completion ( str word -- { score indices word } )
    [
        word-name [ swap fuzzy ] keep swap [ score ] keep
    ] keep
    3array ;

: completions ( str -- seq )
    all-words [ completion ] map-with [ first zero? not ] subset
    [ [ first ] 2apply swap - ] sort dup length 20 min head ;

: fuzzy. ( fuzzy full -- )
    dup length [
        pick member?
        [ hilite-style >r ch>string r> format ] [ write1 ] if 
    ] 2each drop ;

: apropos ( str -- )
    completions [
        first3 dup presented associate [
            dup word-vocabulary write bl word-name fuzzy.
            " (score: " swap >fixnum number>string ")" append3
            write
        ] with-nesting terpri
    ] each ;
