.model small
.stack
    CR		equ		0dh
    LF		equ		0ah
.data
;######################################## AREA DE DADOS
    ;X                   db      8
    ;X                   dq      0               ;variavel de 64 bits que armazena o codigo de verificacao
    Y                   dw      0,0,0,0              
    V                   DB      63999 DUP (?)   ;vetor de bytes que representa o arquivo ///64741
    MsgCRLF				db	    CR, LF, 0
    linhaDeComando      db		256 dup (?)		; string da linha de comando
    fileName            db		256 dup (?)		; nomedoarquivo.txt
    verificationCode    db		256 dup (?)		; codigo de verificacao a ser testado
    fileBuffer		    db		10 dup (?)		; Buffer de leitura do arquivo
    fileHandle		    dw		0				; Handler do arquivo
    auxdb       		db		0	
    auxdw               dw      0
    fileBytes           dw		0
    tamFile             dw      20
;######################################## FIM AREA DE DADOS
.code
.startup
;######################################## int main()
    call    salvaLinhaDeComando         ;salva a string digitada na linha de comando na variavel linhaDeComando
    call    getFileName                 ;armazena o nome do arquivo na variavel fileName
    call    getVerificationCode         ;armazena o codigo de verificacao fornecido (se tiver) na variavel verificationCode
    call    abreFile                    ;abre arquivo fileName
    call    salvaVetBytes               ;salva bytes lidos em fileName no vetor V e salva numero de bytes lidos em fileBytes                       
    call    atoiVerificationCode
;loop for
    ;lea bp,V
    ;mov cx,fileBytes    ; iterations
    
    ;loop1:   
    ;mov     ax,[bp]
    ;add     Y,ax
    ;add     bp,2   
    ;loop    loop1  ; loop instruction decrements cx and jumps to label if not 0

    ;;caso2 + 9999h = xí
    ;mov     Y,7DFh
    ;add     Y,9999h
    
    ;;caso3 * 3333h = äH
    ;mov     Y,7DFh
    ;add     Y,3333h
    
    
    
    ;lea     bx,Y
    mov     aux2,ax
    lea     bx,aux2

    cmp     aux2,61h
    jne     endOfFile

    call    printf_s 




endOfFile:
    call    fechaFile
;######################################## return 0
.exit
;--------------------------------------------------------------------
;Funcao que imprime string na tela
;--------------------------------------------------------------------
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
printf_s	endp
;--------------------------------------------------------------------
;Funcao que salva string da linha de comando na variavel linhaDeComando
;--------------------------------------------------------------------
salvaLinhaDeComando    proc    near
    push ds ; salva as informações de segmentos
    push es
    mov ax,ds ; troca DS <-> ES, para poder usa o MOVSB
    mov bx,es
    mov ds,bx
    mov es,ax
    mov si,80h ; obtém o tamanho do string e coloca em CX
    mov ch,0
    mov cl,[si]
    mov si,81h ; inicializa o ponteiro de origem
    lea di,linhaDeComando ; inicializa o ponteiro de destino
    rep movsb
    pop es ; retorna as informações dos registradores de segmentos 
    pop ds
    ret
salvaLinhaDeComando    endp
;--------------------------------------------------------------------
;Funcao que salva o nome do arquivo na variavel fileName
;--------------------------------------------------------------------
getFileName    proc    near

    mov     SI, OFFSET linhaDeComando
    lea     BP,fileName
repete1:
    LODSB
    cmp     al,0 
    je      fim   
    mov     aux,al
    cmp     aux,'-'
    je      hifen
    jmp     repete1

hifen:
    LODSB
    mov     aux,al
    cmp     aux,'a'
    je      lefile
    jmp     repete1

lefile:
    LODSB
repete2:
    LODSB
    mov     aux,al
    cmp     aux,32
    je      fim
    cmp     aux,0
    je      fim

    mov     [BP],al
    add     bp,1

    jmp     repete2

fim:	
    ret

getFileName    endp
;--------------------------------------------------------------------
;Funcao que verifica se deve calcular o codigo de verificacao
;--------------------------------------------------------------------
getVerificationFlag    proc    near


	
    ret

getVerificationFlag    endp
;--------------------------------------------------------------------
;Funcao que verifica se deve calcular o codigo de verificacao
;--------------------------------------------------------------------
getVerificationCode    proc    near

        mov     SI, OFFSET linhaDeComando
        lea     BP,verificationCode
repete3:
    LODSB
    cmp     al,0 
    je      fim2   
    mov     aux,al
    cmp     aux,'-'
    je      hifen2
    jmp     repete3

hifen2:
    LODSB
    mov     aux,al
    cmp     aux,'v'
    je      lefile2
    jmp     repete3

lefile2:
    LODSB
repete4:
    LODSB
    mov     aux,al
    cmp     aux,32
    je      fim2
    cmp     aux,0
    je      fim2

    mov     [BP],al
    add     bp,1

    

    jmp     repete4

fim2:	
    ret

getVerificationCode    endp
;--------------------------------------------------------------------
; Função para abrir arquivo com nome em fileName e handle em fileHandle
;--------------------------------------------------------------------
abreFile    proc    near

    lea		dx,fileName
    mov		ah,3dh  
    int		21h
    mov		fileHandle,ax  
    mov		bx,fileHandle


ret
abreFile    endp
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
fechaFile    proc    near

    mov		bx,fileHandle
	mov		ah,3eh              ;funcao da interrupcao para fechar arquivo 
	int		21h

ret
fechaFile    endp
;--------------------------------------------------------------------
;salva os bytes lidos no vetor V e armazena o numero de bytes lidos em fileBytes
;--------------------------------------------------------------------
salvaVetBytes   proc    near

lea     bp,V        ;ponteiro para vetor
leByte:
    mov     dx,offset fileBuffer
    mov     cx,1
    mov     bx,fileHandle
    mov     ah,3Fh  
    int     21H
    ;jc     readerror
    cmp     ax,0    ;testa se chegou no fim do arquivo
    je      fimSalvaVet

;trata byte lido (fileBuffer = byte lido)
     

    ;move o byte lido para a posicao correspondente no vetor V
    mov     ax,0
    mov     al,fileBuffer
    add     Y,ax
    mov     [bp],ax 

    ;imprime a posicao do vetor apos armazenar o byte lido
    lea     bx,[bp]
    call    printf_s

    add     fileBytes,1 ;incrementa 1 no numero de bytes totais lidos
    add     bp,1 ;incrementa uma posicao do vetor

    jmp     leByte

fimSalvaVet:
ret

salvaVetBytes   endp
;--------------------------------------------------------------------
;Ascii to hexa
;--------------------------------------------------------------------
atohVerificationCode	proc near

        lea     bx,verificationCode
		; A = 0;
		mov		ax,0
		
loopAtoh:
		; while (*S!='\0') {
		cmp		byte ptr[bx],0
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

fimAtoh:
		; return
		ret

atohVerificationCode	endp
;--------------------------------------------------------------------   
    
    
    end