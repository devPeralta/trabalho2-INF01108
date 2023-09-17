.model small

.stack
    CR		equ		0dh     ; carriage return
    LF		equ		0ah     ; linefeed
    SC      equ     3bH     ; ascii ';'
    PL      equ     2bH     ; ascii '+'

.data
;----------------------------------------------------------------------------------------
;-------------------------------------- VARIAVEIS ---------------------------------------
;----------------------------------------------------------------------------------------

    ;;mensagens de erro
    naoEncontrado       db		" nao encontrado.",CR,LF,0
    smallFilePrint      db		"ERRO: Arquivo muito pequeno. Minimo de letras necessarias no arquivo: ",0
    msgFileInEmpty      db      "ERRO: Arquivo de entrada nao informado.",CR,LF,0
    msgFileOutEmpty     db      "ERRO: Arquivo de saida nao informado.",CR,LF,0
    strLetError1        db      "ERRO: Letra ",0
    strLetError2        db      " encontrada no arquivo de entrada.",0
    bigFilePrint        db      "Erro: Arquivo muito grande.",0
    ;;cabecalho do arquivo de saida
    headerA	            db		"A",SC,0
    headerT	            db		"T",SC,0
    headerC	            db		"C",SC,0
    headerG	            db		"G",SC,0
    headerPlus1	        db		"A+T",SC,0
    headerPlus2	        db		"C+G",CR,LF,0
    ;;strings especiais e auxiliares
    msgCRLF				db	    CR, LF, 0       ; nova linha
    semicolon           db      SC, 0           ; ponto e virgula
    auxdb       		db		0	            ; variavel auxiliar byte
    auxdw               dw      0               ; variavel auxiliar word
    ;;variaveis da linha de comando
    commandLine         db		256 dup (?)		; linha de comando
    fileNameIn          db		256 dup (?)		; arquivodeentrada.txt
    fileNameOut         db		256 dup (?)		; arquivodesaida.txt
    fileNumLet          db      256 dup (?)     ; string (numero) do tamanho do grupo de letras
    fileAtcg            db      256 dup (?)     ; codigo atcg+
    fileIntNumLet       dw      0               ; fileIntNumLet = atoi(fileNumLet)
    ;;variaveis de arquivo
    fileHandle		    dw		0				; handler do arquivo
    fileByteBuffer      dw      0               ; byte lido no arquivo
    noFileName          db      "a.out", 0      ; arquivo de saida default 
    flagNoFileOut       db      0               ; flag que informa se foi informado um arquivo de saida
    flagFileInEmpty     db      0               ; flag que informa se o arquivo de entrada foi informado
    flagFileOutEmpty    db      0               ; flag que informa se o arquivo de saida foi informado
    ;;flags ATCG para verificar se a letra foi requisitada
    flagA               db      0
    flagT               db      0
    flagC               db      0
    flagG               db      0
    flagPlus            db      0
    ;;variaveis que armazenam as quantidades das bases nitrogenadas lidas
    counterA            dw      0       
    counterT            dw      0
    counterC            dw      0
    counterG            dw      0
    counterAT           dw      0
    counterCG           dw      0
    ;;strings dos contadores atcg
    numA                db      20 dup (?)
    numT                db      20 dup (?)
    numC                db      20 dup (?)
    numG                db      20 dup (?)
    numAT               db      20 dup (?)
    numCG               db      20 dup (?)
    ;;string auxiliar
    strAux              db      20 dup (?)
    ;;outras variaveis 
    deslocamento        dw      0               ;representa o deslocamento para ler o proximo byte do arquivo            
    contLoopGroup       dw      0               ;contador para o looping principal do programa, cada incremento representa uma linha do arquivo de saida
    currentLine         dw      1               ;linha atual do arquivo de entrada  [NAO IMPLEMENTADO]

.code
.startup
    
;----------------------------------------------------------------------------------------
;----------------------------------------- MAIN -----------------------------------------
;----------------------------------------------------------------------------------------
    call    getCommandLine  ;salva string digitada na linha de comando na variavel commandLine
    
    call    getFileNameIn   ;salva nome do arquivo de entrada em fileNameIn

    ;;verifica se fileNameIn esta vazio
    mov     al,[fileNameIn] 
    cmp     al,0           
    jne     fileInNotEmpty      
    mov     flagFileInEmpty,1
    fileInNotEmpty:

    call    getFileNameOut  ;salva nome do arquivo de saida em fileNameOut

    cmp     flagNoFileOut,0
    jne     fileOutNotEmpty

    ;;verifica se fileNameOut esta vazio
    mov     al,[fileNameOut] 
    cmp     al,0           
    jne     fileOutNotEmpty      
    mov     flagFileOutEmpty,1
    fileOutNotEmpty:
    
    call    getNumLet       ;salva numero do grupo de letras em fileNumLet e codigo atcg em fileAtcg
    
    ;;se o arquivo de entrada ou de saida nao foi informado encerra o programa e imprime mensagem na tela
    cmp     flagFileInEmpty,1
    je      fimfim
    cmp     flagFileOutEmpty,1
    je      fimfim

    call    openFile        ;abre arquivo fileNameIn

    ;;fileIntNumLet = atoi(fileNumLet)
    lea     bx,fileNumLet
    call    atoi
    mov     fileIntNumLet,ax

    ;;loop principal do programa (cada looping representa um grupo de letras)
    loopGroup: 
    ;;testa se leu N letras (N = fileIntNumLet)
    inc     contLoopGroup
    mov     ax,contLoopGroup
    mov     bx,fileIntNumLet
    cmp     ax,bx
    je      fimLoopGroup 
    
    ;;le proximo byte do arquivo e verifica se chegou ao fim do arquivo
    call    readFile
    cmp     ax,0
    je      fim
    
    ;;verifica qual foi o byte lido
    cmp     fileByteBuffer,'A'
    je      incA
    cmp     fileByteBuffer,'T'
    je      incT
    cmp     fileByteBuffer,'C'
    je      incC
    cmp     fileByteBuffer,'G'
    je      incG
    dec     contLoopGroup   ;decrementa em 1 o contador principal quando há CRLF
    cmp     fileByteBuffer,CR
    je      loopGroup
    cmp     fileByteBuffer,LF
    je      loopGroup

    jmp     fakeChar        ;char nao reconhecido no arquivo de entrada

    ;incrementa o contador da letra lida
    incA:
    inc     counterA
    jmp     loopGroup
    incT:
    inc     counterT
    jmp     loopGroup
    incC:
    inc     counterC
    jmp     loopGroup
    incG:
    inc     counterG
    jmp     loopGroup
    
    fimLoopGroup:
    
    call    itoaCounters   ;converte contadores em strings para poder imprimir no arquivo de saida

    ;###### inicio impressao no arquivo de saida
    push bx
    
    cmp     flagNoFileOut,0
    je      openFileOut
    ;;abre arquivo de saida default
    mov ah, 3dh           
    lea dx, noFileName   
    mov al, 1              
    int 21h 
    jmp fimOpenFileOut
    ;;abre arquivo de saida informado na linha de comando
    openFileOut:
    mov ah, 3dh           
    lea dx, fileNameOut   
    mov al, 1              
    int 21h              

    fimOpenFileOut:
    mov bx, ax             ; bx = handle do arquivo 

    ;;escreve o cabecalho antes de iniciar a impressao das contagens de atcg, por exemplo: A;T;C;G;A+T;C+G
    mov ax,deslocamento
    cmp ax,0
    jne notFirst
    cmp flagA,0
    je  skipHeadA
    mov ah, 40h             
    lea dx, headerA          
    mov cx, 2                
    int 21h 
    skipHeadA:
    cmp flagT,0
    je  skipHeadT
    mov ah, 40h             
    lea dx, headerT          
    mov cx, 2                
    int 21h 
    skipHeadT:
    cmp flagC,0
    je  skipHeadC
    mov ah, 40h             
    lea dx, headerC          
    mov cx, 2                
    int 21h 
    skipHeadC:
    cmp flagG,0
    je  skipHeadG
    mov ah, 40h             
    lea dx, headerG          
    mov cx, 2                
    int 21h 
    skipHeadG:
    cmp flagPlus,0
    je  skipHeadPlus
    mov ah, 40h             
    lea dx, headerPlus1          
    mov cx, 4                
    int 21h 
    mov ah, 40h             
    lea dx, headerPlus2          
    mov cx, 5                
    int 21h 
    skipHeadPlus:

    notFirst:
    mov ah, 42h            ; Código da função para posicionar o cursor
    mov al, 2              ; Modo de posição (00h start of file - 01h current file position - 02h end of file)
    mov dx, 0              ; deslocamento 
    mov cx, 0              ; Alta parte do offset (zerada)
    int 21h 
    
    mov ah, 40h             
    lea dx, msgCRLF          
    mov cx, 2                
    int 21h     

    ;;; A ;;;
    cmp flagA,0
    je  insertT
    mov ah, 40h             
    lea dx, numA             
    mov cx, 3                
    int 21h    
    mov ah, 40h             
    lea dx, semicolon        
    mov cx, 1                
    int 21h   

    ;;; T ;;;
    insertT:
    cmp flagT,0
    je  insertC
    mov ah, 40h             
    lea dx, numT            
    mov cx, 3                
    int 21h     
    mov ah, 40h             
    lea dx, semicolon        
    mov cx, 1                
    int 21h   

    ;;; C ;;;
    insertC:
    cmp flagC,0
    je  insertG
    mov ah, 40h             
    lea dx, numC           
    mov cx, 3                
    int 21h   
    mov ah, 40h             
    lea dx, semicolon        
    mov cx, 1                
    int 21h   

    ;;; G ;;;
    insertG:
    cmp flagG,0
    je  insertPlus
    mov ah, 40h             
    lea dx, numG            
    mov cx, 3                
    int 21h  
    mov ah, 40h             
    lea dx, semicolon        
    mov cx, 1                
    int 21h   

    ;;; AT ;;;
    insertPlus:
    cmp flagPlus,0
    je  skipPlus
    mov ah, 40h             
    lea dx, numAT            
    mov cx, 4                
    int 21h  
    mov ah, 40h             
    lea dx, semicolon        
    mov cx, 1                
    int 21h   
        
    ;;; CG ;;;
    mov ah, 40h             
    lea dx, numCG            
    mov cx, 4                
    int 21h  
    
    skipPlus:
    ;;fecha arquivo de saida
    mov ah, 3Eh           
    int 21h                

    pop bx
    ;###### fim impressao no arquivo de saida

    ;;desloca o cursor de leitura para o proximo byte do arquivo
    inc     deslocamento
    mov     ax,0
    add     ax,deslocamento
    add     ax,fileIntNumLet
    cmp     ax,9999
    je      bigFile

    call    incOffsetFile

    ;;reseta variaveis de contagem
    mov     contLoopGroup,-1 ;TODO: mov contLoopGroup,0
    mov     counterA,0
    mov     counterT,0
    mov     counterC,0
    mov     counterG,0

    jmp     loopGroup

    fakeChar:
    ;;detectado caractere incorreto no arquivo de entrada
    lea     bx,strLetError1
    call    printf_s
    lea     bx,fileByteBuffer
    call    printf_s
    lea     bx,strLetError2
    call    printf_s

    jmp     fimfimfim

    bigFile:
    lea     bx,bigFilePrint
    call    printf_s
    jmp     fimfimfim

    fim:    
    ;;verifica se o arquivo é muito pequeno
    inc     contLoopGroup
    mov     ax,contLoopGroup
    mov     bx,fileIntNumLet
    cmp     ax,bx
    je      fimfim
    lea     bx,smallFilePrint
    call    printf_s   
    lea     bx,fileNumLet
    call    printf_s

    fimfim:
    ;;verifica se arquivo de entrada ou de saida houve erro na linha de comando
    cmp     flagFileInEmpty,1
    jne     fimFileInNotEmpty
    lea     bx,msgFileInEmpty
    call    printf_s
    fimFileInNotEmpty:
    cmp     flagFileOutEmpty,1
    jne     fimFileOutNotEmpty
    lea     bx,msgFileOutEmpty
    call    printf_s
    fimFileOutNotEmpty:
    fimfimfim: 
.exit
;----------------------------------------------------------------------------------------
;-------------------------------------- FUNCTIONS ---------------------------------------
;----------------------------------------------------------------------------------------

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
    je      notFoundFileOut
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
    notFoundFileOut:
    mov flagNoFileOut,1

    ;cria arquivo a.out
    mov ah, 3Ch                
    lea dx, noFileName        
    mov cx, 0                 
    int 21h                   

    fimGetFileNameOut:	
    ret

getFileNameOut  endp
;
;--------------------------------------------------------------------
;Funcao que salva o numero do grupo de letras e o codigo atcg
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
    ;lea     BP,fileAtcg
    loopNumLet:
    LODSB
    ;LODSB
    ;TODO: precisa sair do looping e retornar algum erro caso seja digitado -n e nao seja digitada o codigo atcg, caso contrario entrara em looping infinito
    mov     auxdb,al
    cmp     auxdb,'-'
    jne     loopNumLet ;TODO: aqui deveria ter um jmp pra um erro
    loopAtcgRead:
    LODSB
    mov     auxdb,al
    cmp     auxdb,' '
    je      fimfimGetNumLet
    cmp     auxdb,'a'
    je      flagAon
    cmp     auxdb,'t'
    je      flagTon
    cmp     auxdb,'c'
    je      flagCon
    cmp     auxdb,'g'
    je      flagGon
    cmp     auxdb,PL
    je      flagPlusOn
    retFlag:
    ;mov     [BP],al
    ;add     bp,1
    jmp     fimfimGetNumLet   

    flagAon:
    mov     flagA,1
    jmp     loopAtcgRead
    flagTon:
    mov     flagT,1
    jmp     loopAtcgRead
    flagCon:
    mov     flagC,1
    jmp     loopAtcgRead
    flagGon:
    mov     flagG,1
    jmp     loopAtcgRead
    flagPlusOn:
    mov     flagPlus,1
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

    jc      fileNotFound

    mov		fileHandle,ax  
    
    mov		bx,fileHandle
    jmp     fimOpenFile

    fileNotFound:
    lea     bx,fileNameIn
    call    printf_s
    lea     bx,naoEncontrado
    call    printf_s
fimOpenFile:
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
; Funcao de deslocamento do cursor no arquivo
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

		mov		ax,0
atoi_2:
		cmp		byte ptr[bx], 0
		jz		atoi_1
		mov		cx,10
		mul		cx
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx
		sub		ax,'0'
		inc		bx
		jmp		atoi_2
atoi_1:
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
    mov bx, di             ; salva o endereço da string em BX

itoa_loop:
    xor dx, dx
    div cx
    add dl, '0'
    mov [di], dl

    inc di

    cmp ax, 0
    jnz itoa_loop

    mov [di], 0

    ;;inverte a string
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

    mov ax,0
    add ax,counterA
    add ax,counterT
    mov counterAT,ax
    mov ax,0
    add ax,counterC
    add ax,counterG
    mov counterCG,ax

    lea di, numAT          
    mov ax, counterAT
    call itoa 
    lea di, numCG          
    mov ax, counterCG
    call itoa 

    ret
itoaCounters endp
;
end