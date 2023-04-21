:fonc:puissance:1
;declaration
    const ax,decl:after:1
    jmp ax
;p = 1
:fonc:puissance:1:p
@int 1
:decl:after:1
;k = 1
    const ax,decl:after:2
    jmp ax
:fonc:puissance:1:k
@int 1
:decl:after:2
:loop:for:begin:1
;check boucle for
    const dx,fonc:puissance:1:k
    loadw ax,dx
    const dx,val:puissance:b
    loadw bx,dx
    const cx,loop:for:end:1
;jump si la condition est fini ici k = b
    sless bx,ax
    jmpc cx
    const dx,fonc:puissance:1:p
    loadw ax,dx
    const dx,val:puissance:a
    loadw bx,dx
    mul ax,bx
    const dx,fonc:puissance:1:p
    storew ax,dx
    const dx,fonc:puissance:1:k
    loadw ax,dx
    const bx,1
    add ax,bx
    const dx,fonc:puissance:1:k
    storew ax,dx
    const dx,loop:for:begin:1
    jmp dx
:loop:for:end:1
