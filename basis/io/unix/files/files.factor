! Copyright (C) 2005, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: io.backend io.ports io.unix.backend io.files io
unix unix.stat unix.time kernel math continuations
math.bitwise byte-arrays alien combinators calendar
io.encodings.binary accessors sequences strings system
io.files.private destructors vocabs.loader ;

IN: io.unix.files

M: unix cwd ( -- path )
    MAXPATHLEN [ <byte-array> ] keep getcwd
    [ (io-error) ] unless* ;

M: unix cd ( path -- ) [ chdir ] unix-system-call drop ;

: read-flags O_RDONLY ; inline

: open-read ( path -- fd ) O_RDONLY file-mode open-file ;

M: unix (file-reader) ( path -- stream )
    open-read <fd> init-fd <input-port> ;

: write-flags { O_WRONLY O_CREAT O_TRUNC } flags ; inline

: open-write ( path -- fd )
    write-flags file-mode open-file ;

M: unix (file-writer) ( path -- stream )
    open-write <fd> init-fd <output-port> ;

: append-flags { O_WRONLY O_APPEND O_CREAT } flags ; inline

: open-append ( path -- fd )
    [
        append-flags file-mode open-file |dispose
        dup 0 SEEK_END lseek io-error
    ] with-destructors ;

M: unix (file-appender) ( path -- stream )
    open-append <fd> init-fd <output-port> ;

: touch-mode ( -- n )
    { O_WRONLY O_APPEND O_CREAT O_EXCL } flags ; foldable

M: unix touch-file ( path -- )
    normalize-path
    dup exists? [ touch ] [
        touch-mode file-mode open-file close-file
    ] if ;

M: unix move-file ( from to -- )
    [ normalize-path ] bi@ rename io-error ;

M: unix delete-file ( path -- ) normalize-path unlink-file ;

M: unix make-directory ( path -- )
    normalize-path OCT: 777 mkdir io-error ;

M: unix delete-directory ( path -- )
    normalize-path rmdir io-error ;

: (copy-file) ( from to -- )
    dup parent-directory make-directories
    binary <file-writer> [
        swap binary <file-reader> [
            swap stream-copy
        ] with-disposal
    ] with-disposal ;

M: unix copy-file ( from to -- )
    [ normalize-path ] bi@
    [ (copy-file) ]
    [ swap file-info permissions>> chmod io-error ]
    2bi ;

HOOK: stat>file-info os ( stat -- file-info )

HOOK: stat>type os ( stat -- file-info )

HOOK: new-file-info os ( -- class )

TUPLE: unix-file-info < file-info uid gid dev ino
nlink rdev blocks blocksize ;

M: unix file-info ( path -- info )
    normalize-path file-status stat>file-info ;

M: unix link-info ( path -- info )
    normalize-path link-status stat>file-info ;

M: unix make-link ( path1 path2 -- )
    normalize-path symlink io-error ;

M: unix read-link ( path -- path' )
   normalize-path read-symbolic-link ;

M: unix new-file-info ( -- class ) unix-file-info new ;

M: unix stat>file-info ( stat -- file-info )
    [ new-file-info ] dip
    {
        [ stat>type >>type ]
        [ stat-st_size >>size ]
        [ stat-st_mode >>permissions ]
        [ stat-st_ctim timespec>unix-time >>created ]
        [ stat-st_mtim timespec>unix-time >>modified ]
        [ stat-st_atim timespec>unix-time >>accessed ]
        [ stat-st_uid >>uid ]
        [ stat-st_gid >>gid ]
        [ stat-st_dev >>dev ]
        [ stat-st_ino >>ino ]
        [ stat-st_nlink >>nlink ]
        [ stat-st_rdev >>rdev ]
        [ stat-st_blocks >>blocks ]
        [ stat-st_blksize >>blocksize ]
    } cleave ;

M: unix stat>type ( stat -- type )
    stat-st_mode S_IFMT bitand {
        { S_IFREG [ +regular-file+ ] }
        { S_IFDIR [ +directory+ ] }
        { S_IFCHR [ +character-device+ ] }
        { S_IFBLK [ +block-device+ ] }
        { S_IFIFO [ +fifo+ ] }
        { S_IFLNK [ +symbolic-link+ ] }
        { S_IFSOCK [ +socket+ ] }
        [ drop +unknown+ ]
    } case ;

! Linux has no extra fields in its stat struct
os {
    { macosx  [ "io.unix.files.macosx"  require ] }
    { freebsd [ "io.unix.files.freebsd" require ] }
    { netbsd  [ "io.unix.files.netbsd"  require ] }
    { openbsd [ "io.unix.files.openbsd" require ] }
} case
