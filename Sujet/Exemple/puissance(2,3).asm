;calculatrice
	const ax,debut
	jmp ax
:debut
;declaration de la pile
	const bp,pile
	const sp,pile
	const ax,2
	sub sp,ax
;fin declaration de la pile
;debut de code
;declaration
	const ax,val:after:1
	jmp ax
:val:puissance:a
@int 2
:val:puissance:b
@int 3
:val:after:1
:fonc:puissance
;declaration
	const ax,decl:after:1
	jmp ax
;p = 1
:fonc:puissance:p
@int 1
:decl:after:1
;k = 1
	const ax,decl:after:2
	jmp ax
:fonc:puissance:k
@int 1
:decl:after:2
:loop:for:begin:1
;check boucle for
	const dx,fonc:puissance:k
	loadw ax,dx
	const dx,val:puissance:b
	loadw bx,dx
	const cx,loop:for:end:1
;jump si la condition est fini ici k = b
	sless bx,ax
	jmpc cx
	const dx,fonc:puissance:p
	loadw ax,dx
	const dx,val:puissance:a
	loadw bx,dx
	mul ax,bx
	const dx,fonc:puissance:p
	storew ax,dx
	const dx,fonc:puissance:k
	loadw ax,dx
	const bx,1
	add ax,bx
	const dx,fonc:puissance:k
	storew ax,dx
	const dx,loop:for:begin:1
	jmp dx
:loop:for:end:1
	const dx,fonc:puissance:p
	callprintfd dx
;fin de code
	end
:pile
@int 0
