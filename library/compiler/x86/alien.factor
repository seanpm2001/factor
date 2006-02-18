! Copyright (C) 2005 Slava Pestov.
! See http://factor.sf.net/license.txt for BSD license.
IN: compiler-backend
USING: alien arrays assembler compiler inference kernel
kernel-internals lists math memory namespaces words ;

GENERIC: push-return-reg ( reg-class -- )
GENERIC: pop-return-reg ( reg-class -- )
GENERIC: load-return-reg ( stack@ reg-class -- )

M: int-regs push-return-reg drop EAX PUSH ;
M: int-regs pop-return-reg drop EAX POP ;
M: int-regs load-return-reg
    drop ECX ESP MOV  EAX ECX rot 2array MOV ;

: FSTP 4 = [ FSTPS ] [ FSTPL ] if ;

M: float-regs push-return-reg
    ESP swap reg-size [ SUB  { ECX } ] keep ECX ESP MOV FSTP ;

: FLD 4 = [ FLDS ] [ FLDL ] if ;

M: float-regs pop-return-reg
    ECX ESP MOV  reg-size { ECX } over FLD ESP swap ADD ;

M: float-regs load-return-reg
    reg-size >r ECX ESP MOV  ECX swap 2array r> FLD ;

M: %unbox generate-node
    drop 2 input f compile-c-call  1 input push-return-reg ;

M: %unbox-struct generate-node ( vop -- )
    drop
    ! Increase stack size
    ESP 2 input SUB
    ! Save destination address in EAX
    EAX ESP MOV
    ! Load struct size
    2 input PUSH
    ! Load destination address
    EAX PUSH
    ! Copy the struct to the stack
    "unbox_value_struct" f compile-c-call
    ! Clean up
    EAX POP
    ECX POP ;

M: %box generate-node
    drop
    0 input [ 4 + 1 input load-return-reg ] when*
    1 input push-return-reg
    2 input f compile-c-call
    1 input pop-return-reg ;

M: %alien-callback generate-node ( vop -- )
    drop
    EAX 0 input load-indirect
    EAX PUSH
    "run_callback" f compile-c-call
    EAX POP ;

M: %callback-value generate-node ( vop -- )
    drop
    ! Call the unboxer
    1 input f compile-c-call
    ! Save return register
    0 input push-return-reg
    ! Restore data/callstacks
    "unnest_stacks" f compile-c-call
    ! Restore return register
    0 input pop-return-reg ;

M: %cleanup generate-node
    drop 0 input dup zero? [ drop ] [ ESP swap ADD ] if ;
