.model small

.stack
    CR		equ		0dh
    LF		equ		0ah
    SC      equ     03bH
.data

    ;;strings inicializadas
    Texto1	            db		"Primeira letra do arquivo: ",0
    Texto2	            db		"Segunda letra do arquivo: ",0
    msgCRLF				db	    CR, LF, 0
    semicolon           db      SC, 0
    vacuo               db      "   ", 0
    ;;variaveis auxiliares
    auxdb       		db		0	            ; variavel auxiliar byte
    auxdw               dw      0               ; variavel auxiliar word
    ;;variaveis da linha de comando
    commandLine         db		256 dup (?)		; linha de comando
    fileNameIn          db		256 dup (?)		; arquivodeentrada.txt
    fileNameOut         db		256 dup (?)		; arquivodesaida.txt
    fileNumLet          db      256 dup (?)     ; string (numero) do tamanho do grupo de letras
    fileAtcg            db      256 dup (?)     ; codigo atcg+
    fileIntNumLet       dw      0               ; fileIntNumLet = atoi(fileNumLet)
    ;;
    fileHandle		    dw		0				; Handler do arquivo
    fileByteBuffer      dw      0    
    ;;variaveis que armazenam as quantidades das bases nitrogenadas lidas
    counterA            dw      0       
    counterT            dw      0
    counterC            dw      0
    counterG            dw      0
    ;;strings dos contadores atcg
    numA               db      20 dup (?)
    numT               db      20 dup (?)
    numC               db      20 dup (?)
    numG               db      20 dup (?)
    ;;flag para subtrair 1 na contagem da letra que saiu do gap do grupo de letras (primeira letra do grupo anterior)
    ;;0 = erro ; 1 = letra A ; 2 = letra T ; 3 = letra C ; 4 = letra G
    

    ;;
    deslocamento        dw      0
    posFirstChar        dw      0
    currentPos          dw      2
    firstChar           db      0
    contLoopFirstGroup  dw      -1


.code
.startup
    
    ;;separa cada informacao da linha de comando em variaveis diferentes
    call    getCommandLine  ;salva string digitada na linha de comando na variavel commandLine
    call    getFileNameIn   ;salva nome do arquivo de entrada em fileNameIn
    call    getFileNameOut  ;salva nome do arquivo de saida em fileNameOut
    call    getNumLet       ;salva numero do grupo de letras em fileNumLet e codigo atcg em fileAtcg
    
    call    openFile    ;abre arquivo fileNameIn

    lea     bx,fileNumLet
    call    atoi
    mov     fileIntNumLet,ax

    ;;loop que le e faz a contagem das primeiras n letras (n=fileIntNumLet)
    loopFirstGroup: 
    ;;
    inc     contLoopFirstGroup
    mov     ax,contLoopFirstGroup
    mov     bx,fileIntNumLet
    cmp     ax,bx;
    je      fimLoopFirstGroup 
    
    ;;le proximo byte do arquivo e verifica se chegou ao fim
    call    readFile    
    cmp     ax,0
    je      fim
    
    cmp     fileByteBuffer,'A'
    je      incA
    cmp     fileByteBuffer,'T'
    je      incT
    cmp     fileByteBuffer,'C'
    je      incC
    cmp     fileByteBuffer,'G'
    je      incG
    cmp     fileByteBuffer,CR
    je      loopFirstGroup
    cmp     fileByteBuffer,LF
    je      loopFirstGroup

    jmp     fim ;TODO: erro se nao for A,T,C ou G

    incA:
    inc     counterA
    jmp     loopFirstGroup
    incT:
    inc     counterT
    jmp     loopFirstGroup
    incC:
    inc     counterC
    jmp     loopFirstGroup
    incG:
    inc     counterG
    jmp     loopFirstGroup
    
    fimLoopFirstGroup:
    
    call    printGroup  

    lea     bx,vacuo
    call    printf_s
    lea     bx,vacuo
    call    printf_s

    ;;desloca o cursor de leitura para o proximo byte do arquivo
    inc     deslocamento
    call    incOffsetFile

    ;;reseta variaveis de contagem
    mov     contLoopFirstGroup,-1
    mov     counterA,0
    mov     counterT,0
    mov     counterC,0
    mov     counterG,0

    jmp     loopFirstGroup
fim:
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
;------------------------------------------atcg----------------------------
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
    
    mov		bx,fileHandle
ret
openFile    endp
;
;--------------------------------------------------------------------
; Função para ler o arquivo
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
;--------------------------------------------------------------------
; Recebe um inteiro/posicao no AX e salva em firstChar o char correspondente a essa posicao
;--------------------------------------------------------------------
incOffsetFile    proc    near
    
    mov ah, 42h            ; Código da função para posicionar o cursor
    mov al, 00h            ; Modo de posição (00h start of file - 01h current file position - 02h end of file)
    mov bx, fileHandle
    mov dx, deslocamento                 ; deslocamento 
    mov cx, 0              ; Alta parte do offset (zerada)
    int 21h  

ret
incOffsetFile    endp
;
;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;   entrada = bx
;   saida   = ax
;   exemplo:
;               lea		bx,string
;		        call	atoi
;               mov     numero,ax
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp
;
;----------------------------------------------------------------------
; Função itoa
;       Entrada: AX contém o valor inteiro a ser convertido
;                DI apontando para a string de destino (stringK)
;----------------------------------------------------------------------
itoa proc near
    mov cx, 10
    mov bx, di             ; Salva o endereço da string em BX

itoa_loop:
    xor dx, dx
    div cx
    add dl, '0'
    mov [di], dl

    inc di

    cmp ax, 0
    jnz itoa_loop

    mov [di], 0

    ; Inverte a string
    dec di

itoa_reverse_loop:
    cmp bx, di
    jae itoa_done

    mov al, [bx]
    mov ah, [di]
    mov [bx], ah
    mov [di], al

    inc bx
    dec di

    jmp itoa_reverse_loop

itoa_done:
    ret
itoa endp
;
;----------------------------------------------------------------------
; Faz um itoa para todos os contadores
;----------------------------------------------------------------------
itoaCounters proc near

    lea di, numA          
    mov ax, counterA
    call itoa 
    lea di, numT          
    mov ax, counterT
    call itoa 
    lea di, numC          
    mov ax, counterC
    call itoa 
    lea di, numG          
    mov ax, counterG
    call itoa 

    ret
itoaCounters endp
;----------------------------------------------------------------------
; Imprime linha de contagem do grupo de letras atual
;----------------------------------------------------------------------
printGroup proc near

call    itoaCounters
    lea     bx,numA
    call    printf_s 
    lea     bx,semicolon
    call    printf_s   
    lea     bx,numT
    call    printf_s 
    lea     bx,semicolon
    call    printf_s    
    lea     bx,numC
    call    printf_s 
    lea     bx,semicolon
    call    printf_s   
    lea     bx,numG
    call    printf_s

    ret
printGroup endp
;
;----------------------------------------------------------------------
; 
;----------------------------------------------------------------------
end