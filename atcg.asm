.model small

.stack
    CR		equ		0dh
    LF		equ		0ah
.data

    ;;strings inicializadas
    Texto1	            db		"Primeira letra do arquivo: ",0
    Texto2	            db		"Segunda letra do arquivo: ",0
    msgCRLF				db	    CR, LF, 0
    ;;variaveis auxiliares
    auxdb       		db		0	            ; variavel auxiliar byte
    auxdw               dw      0               ; variavel auxiliar word
    ;;variaveis da linha de comando
    commandLine         db		256 dup (?)		; linha de comando
    fileNameIn          db		256 dup (?)		; arquivodeentrada.txt
    fileNameOut         db		256 dup (?)		; arquivodesaida.txt
    fileNumLet          db      256 dup (?)     ; string (numero) do tamanho do grupo de letras
    fileAtcg            db      256 dup (?)     ; codigo atcg+
    ;;
    fileHandle		    dw		0				; Handler do arquivo
    fileByteBuffer      db      0    
    ;;variaveis que armazenam as quantidades das bases nitrogenadas lidas
    counterA            db      0       
    counterT            db      0
    counterC            db      0
    counterG            db      0
    ;;flags do codigo atcg+ 
    ;flagA               db      0
    ;flagT               db      0
    ;flagC               db      0
    ;flagG               db      0
    ;flag+               db      0 

    ;;flag para subtrair 1 na contagem da letra que saiu do gap do grupo de letras (primeira letra do grupo anterior)
    ;;0 = erro ; 1 = letra A ; 2 = letra T ; 3 = letra C ; 4 = letra G
    flagLastChar        db      0   


.code
.startup
    
    ;;separa cada informacao da linha de comando em variaveis diferentes
    call    getCommandLine  ;salva string digitada na linha de comando na variavel commandLine
    call    getFileNameIn   ;salva nome do arquivo de entrada em fileNameIn
    call    getFileNameOut  ;salva nome do arquivo de saida em fileNameOut
    call    getNumLet       ;salva numero do grupo de letras em fileNumLet e codigo atcg em fileAtcg


    ;;teste leitura file
    call    openFile    ;abre arquivo fileNameIn
    call    readFile    ;retorna byte lido em fileByteBuffer

    ;; print: primeiras duas letras do arquivo de entrada
    lea     bx,Texto1
    call    printf_s
    lea     bx,fileByteBuffer
    call    printf_s
    lea     bx,msgCRLF
    call    printf_s
    lea     bx,Texto2
    call    printf_s
    call    readFile    ;retorna byte lido em fileByteBuffer
    lea     bx,fileByteBuffer
    call    printf_s
    lea     bx,msgCRLF
    call    printf_s

    ;; print: letras e atcg
    lea     bx,fileNumLet
    call    printf_s
    lea     bx,msgCRLF
    call    printf_s
    lea     bx,fileAtcg
    call    printf_s

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
getFileNameOut  proc    near

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

getFileNameOut  endp
;
;--------------------------------------------------------------------
;Funcao que salva o numero do grupo de letras & codigo atcg+
;--------------------------------------------------------------------
getNumLet   proc    near
    mov     SI, OFFSET commandLine
    lea     BP,fileNumLet
    loopHifenNum:
    LODSB
    cmp     al,0 
    je      fimGetNumLet  
    mov     auxdb,al
    cmp     auxdb,'-'
    je      hifenNum
    jmp     loopHifenNum
    
    hifenNum:
    LODSB
    mov     auxdb,al
    cmp     auxdb,'n'
    je      lefileNum
    jmp     loopHifenNum

    leFileNum:
    LODSB
    loopLeFileNum:
    LODSB
    mov     auxdb,al
    cmp     auxdb,' '
    je      fimGetNumLet 
    cmp     auxdb,0
    je      fimGetNumLet 

    mov     [BP],al
    add     bp,1

    jmp     loopLeFileNum

    fimGetNumLet:
    lea     BP,fileAtcg
    loopNumLet:
    LODSB
    ;LODSB
    ;TO DO: precisa sair do looping e retornar algum erro caso seja digitado -n e nao seja digitada o codigo atcg, caso contrario entrara em looping infinito
    mov     auxdb,al
    cmp     auxdb,'-'
    jne     loopNumLet
    loopAtcgRead:
    LODSB
    mov     auxdb,al
    cmp     auxdb,' '
    je      fimfimGetNumLet
    mov     [BP],al
    add     bp,1
    jmp     loopAtcgRead    

    fimfimGetNumLet:
    ret
getNumLet   endp
;
;--------------------------------------------------------------------
; Função para abrir arquivo com nome em fileNameIn e handle do arquivo em fileHandle
;--------------------------------------------------------------------
openFile    proc    near
    lea		dx,fileNameIn
    mov		ah,3dh  
    int		21h
    mov		fileHandle,ax  
    ;mov		bx,fileHandle
ret
openFile    endp
;
;--------------------------------------------------------------------
; Função teste
;--------------------------------------------------------------------
readFile    proc    near
    mov     ah,3fh
    mov     bx,fileHandle
    mov     cx,1
    lea     dx,fileByteBuffer
    int     21h
ret
readFile    endp
;
end