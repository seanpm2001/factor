! Copyright (C) 2017 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays bootstrap.image calendar cli.git
combinators concurrency.combinators formatting fry http.client
io io.directories io.launcher io.pathnames kernel math.parser
memory modern.paths namespaces parser.notes prettyprint
sequences sequences.extras system system-info threads tools.test
vocabs vocabs.hierarchy vocabs.hierarchy.private vocabs.loader
zealot ;
IN: zealot.factor

: download-boot-checksums ( path branch -- )
    '[ _ "http://downloads.factorcode.org/images/%s/checksums.txt" sprintf download ] with-directory ;

: download-boot-image ( path branch image-name -- )
    '[ _ _ "http://downloads.factorcode.org/images/%s/%s" sprintf download ] with-directory ;

: download-my-boot-image ( path branch -- )
    my-boot-image-name download-boot-image ;

HOOK: compile-factor-command os ( -- array )
M: unix compile-factor-command ( -- array )
    { "make" "-j" } cpus number>string suffix ;
M: windows compile-factor-command ( -- array )
    { "nmake" "/f" "NMakefile" "x86-64" } ;

HOOK: factor-path os ( -- path )
M: unix factor-path "./factor" ;
M: windows factor-path "./factor.com" ;

: compile-factor ( path -- )
    [
        <process>
            compile-factor-command >>command
            "./compile-log" >>stdout
            +stdout+ >>stderr
            +new-group+ >>group
        try-process
    ] with-directory ;

: bootstrap-factor ( path -- )
    [
        <process>
            factor-path "-i=" my-boot-image-name append "-no-user-init" 3array >>command
            +closed+ >>stdin
            "./bootstrap-log" >>stdout
            +stdout+ >>stderr
            30 minutes >>timeout
            +new-group+ >>group
        try-process
    ] with-directory ;

! Meant to run in the child process
: with-child-options ( quot -- )
    f parser-quiet? set-global
    f restartable-tests? set-global
    call ; inline

: zealot-load-and-save ( vocabs path -- )
    dup "load-and-save to " prepend print flush yield
    '[
        [ load ] each _ save-image
    ] with-child-options ;

: zealot-load-basis ( -- ) basis-vocabs "factor.image.basis" zealot-load-and-save ;
: zealot-load-extra ( -- ) extra-vocabs "factor.image.extra" zealot-load-and-save ;

! like ``"" load`` -- only platform-friendly vocabs
: zealot-vocabs-from-root ( root -- seq ) "" vocabs-to-load [ vocab-name ] map ;
: zealot-all-vocabs ( -- seq ) vocab-roots get [ zealot-vocabs-from-root ] map-concat ;
: zealot-core-vocabs ( -- seq ) "resource:core" zealot-vocabs-from-root ;
: zealot-basis-vocabs ( -- seq ) "resource:basis" zealot-vocabs-from-root ;
: zealot-extra-vocabs ( -- seq ) "resource:extra" zealot-vocabs-from-root ;

: zealot-load-all ( -- ) zealot-all-vocabs "factor.image.all" zealot-load-and-save ;

: zealot-load-command ( command log-path -- process )
    <process>
        swap >>stdout
        swap >>command
        +closed+ >>stdin
        +stdout+ >>stderr
        60 minutes >>timeout
        +new-group+ >>group ;

: zealot-load-basis-command ( -- process )
    factor-path "-e=USE: zealot.factor zealot-load-basis" 2array
    "./load-basis-log" zealot-load-command ;

: zealot-load-extra-command ( -- process )
    factor-path "-e=USE: zealot.factor zealot-load-extra" 2array
    "./load-extra-log" zealot-load-command ;

: zealot-load-commands ( path -- )
    [
        zealot-load-basis-command
        zealot-load-extra-command 2array
        [ try-process ] parallel-each
    ] with-directory ;

! Meant to run in the child process
: zealot-test-all ( -- )
    [ test-all ] with-child-options ;

: zealot-test-command ( command log-path -- process )
    <process>
        swap >>stdout
        swap >>command
        +closed+ >>stdin
        +stdout+ >>stderr
        60 minutes >>timeout
        +new-group+ >>group ;

: zealot-test-commands ( path -- )
    [
        factor-path "-i=factor.image" "-e=USE: tools.test test-all" 3array
        "./test-core-log" zealot-test-command

        factor-path "-i=factor.image.basis" "-e=USE: tools.test test-all" 3array
        "./test-basis-log" zealot-test-command

        factor-path "-i=factor.image.extra" "-e=USE: tools.test test-all" 3array
        "./test-extra-log" zealot-test-command 3array

        [ try-process ] parallel-each
    ] with-directory ;

: build-new-factor ( branch -- )
    [ "factor" "factor" zealot-github-clone-paths nip ] dip
    over <pathname> . flush yield
    {
        [ drop "factor" "factor" zealot-github-add-build-remote drop ]
        [ drop [ git-fetch-all* ] with-directory drop ]
        [ zealot-build-checkout-branch drop ]
        [ download-my-boot-image ]
        [ download-boot-checksums ]
        [ drop compile-factor ]
        [ drop bootstrap-factor ]
        [ "ZEALOT LOAD" print flush yield drop zealot-load-commands ]
        [ drop zealot-test-commands ]
    } 2cleave ;