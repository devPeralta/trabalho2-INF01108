.model small

.stack
    CR		equ		0dh
    LF		equ		0ah
.data

    
    Texto1	            db		"Texto numero 1",0
    Texto2	            db		"Hello World",0
    msgCRLF				db	    CR, LF, 0
    auxdb       		db		0	            ; variavel auxiliar byte
    auxdw               dw      0               ; variavel auxiliar word
    commandLine         db		256 dup (?)		; linha de comando
    fileNameIn          db		256 dup (?)		; arquivodeentrada.txt
    fileNameOut         db		256 dup (?)		; arquivodesaida.txt

.code
.startup

    call    getCommandLine  ;salva string digitada na linha de comando na variavel commandLine
    ;lea     bx,commandLine
    ;call    printf_s
    
    call    getFileNameIn   ;salva nome do arquivo de entrada em fileNameIn
    ;lea     bx,fileNameIn
    ;call    printf_s

    ;lea     bx,msgCRLF
    ;call    printf_s

    call    getFileNameOut
    ;lea     bx,fileNameOut
    ;call    printf_s




.exit
;----------------------------------------------------------------------
;Funcao que salva string da linha de comando na variavel commandLine
;----------------------------------------------------------------------
getCommandLine    proc    near
    push ds ; salva as informações de segmentos
    push es
    mov ax,ds ; troca DS <-> ES, para poder usar o MOVSB
    mov bx,es
    mov ds,bx
    mov es,ax
    mov si,80h ; obtém o tamanho do string e coloca em CX
    mov ch,0
    mov cl,[si]
    mov si,81h ; inicializa o ponteiro de origem
    lea di,commandLine ; inicializa o ponteiro de destino
    rep movsb
    pop es ; retorna as informações dos registradores de segmentos 
    pop ds
    ret
getCommandLine    endp
;
;----------------------------------------------------------------------
;Funcao que imprime string na tela
;----------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
    ps_1:
	ret
printf_s    endp
;
;--------------------------------------------------------------------
;Funcao que salva o nome do arquivo de entrada na variavel fileNameIn
;--------------------------------------------------------------------
getFileNameIn   proc    near

    mov     SI, OFFSET commandLine
    lea     BP,fileNameIn
    loopHifenIn:
    LODSB
    cmp     al,0 
    je      fimGetFileNameIn   
    mov     auxdb,al
    cmp     auxdb,'-'
    je      hifenIn
    jmp     loopHifenIn
    
    hifenIn:
    LODSB
    mov     auxdb,al
    cmp     auxdb,'f'
    je      lefileIn
    jmp     loopHifenIn

    leFileIn:
    LODSB
    loopLeFileIn:
    LODSB
    mov     auxdb,al
    cmp     auxdb,' '
    je      fimGetFileNameIn
    cmp     auxdb,0
    je      fimGetFileNameIn

    mov     [BP],al
    add     bp,1

    jmp     loopLeFileIn

    fimGetFileNameIn:	
    ret

getFileNameIn   endp
;
;--------------------------------------------------------------------
;Funcao que salva o nome do arquivo de saida na variavel fileNameOut
;--------------------------------------------------------------------
getfileNameOut  proc    near

    mov     SI, OFFSET commandLine
    lea     BP,fileNameOut
    loopHifenOut:
    LODSB
    cmp     al,0 
    je      fimGetFileNameOut  
    mov     auxdb,al
    cmp     auxdb,'-'
    je      hifenOut
    jmp     loopHifenOut
    
    hifenOut:
    LODSB
    mov     auxdb,al
    cmp     auxdb,'o'
    je      lefileOut
    jmp     loopHifenOut

    leFileOut:
    LODSB
    loopLeFileOut:
    LODSB
    mov     auxdb,al
    cmp     auxdb,' '
    je      fimGetFileNameOut
    cmp     auxdb,0
    je      fimGetFileNameOut

    mov     [BP],al
    add     bp,1

    jmp     loopLeFileOut

    fimGetFileNameOut:	
    ret

getfileNameOut  endp
end