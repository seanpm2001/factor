! Copyright (C) 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
IN: gadgets-books
USING: gadgets gadgets-controls gadgets-panes gadgets-scrolling
kernel sequences models ;

TUPLE: book pages ;

: get-page ( n book -- page ) book-pages nth ;

M: book model-changed ( book -- )
    [ control-model model-value ] keep
    [ gadget-child unparent ] keep
    [ get-page ] keep
    [ control-self add-gadget ] keep
    request-focus ;

C: book ( pages -- book )
    dup 0 <model> delegate>control
    dup dup set-control-self
    [ set-book-pages ] keep
    dup model-changed ;

M: book pref-dim* gadget-child pref-dim ;

M: book layout*
    dup rect-dim swap gadget-child set-layout-dim ;

M: book focusable-child* gadget-child ;
