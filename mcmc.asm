;Maria Cecília Matos Corrêa

    assume cs:codigo,ds:dados,es:dados,ss:pilha

CR      EQU     0DH ; constante - codigo ASCII do caractere "carriage return"
LF      EQU     0AH ; constante - codigo ASCII do caractere "line feed"
TAB	EQU		9H ; constante - codigo ASCII do caractere "TAB"
BS      EQU     8H ; constante - codigo ASCII do caractere "backspace"
ESCAPE	EQU	1BH ; constante - codigo ASCII do caractere "esc"

dados	segment
msgERROab	db		CR, LF, 'Erro de abertura de arquivo:', CR, LF, '$'
erroAB1		db		' - Arquivo nao encontrado.','$'
erroAB2		db		' - Nao ha mais handlers disponiveis.','$'
erroAB3		db		' - Caminho nao encontrado.', '$'
erroAB4		db		' - Acesso negado.', '$'
msgERROle	db		CR, LF, 'Erro de leitura de arquivo.', CR, LF, '$'
NomeArq		db		'Nome do arquivo: ', '$'
cabecalho1	db		'Arquivo ', '$'
filename	db		14 dup(0)
cabecalho2	db		' contendo ', '$'
cabecalho3	db		' caracteres. Eliminados ', '$'
cabecalho4	db		' espacos e TABs.', '$'
msgESC		db		'Comandos: w/W - rolar para cima, s/S - rolar para baixo, ESC - fim da exibicao.', '$'
salvaESP	db		'es$'
msgFim		db		'                     '
msgFim0		db		CR, LF, LF, LF, LF
msgFim1		db		LF, LF, LF, LF
msgFim2		db		'                 -- Maria Cecilia Matos Correa -- ', CR, LF
msgFim3		db		'                           -- 287703 --', CR, LF, LF, LF
msgFim4		db		'                   Foi um prazer ser sua aluna!', '$'
linha		db		0
aux		db		0
nometam		db		0
ptaux		dw		0
dez		dw		0
handler		dw		0
lidos		dw		0
eliminados	dw		0
strLidos	db		7h dup(0)
strElim		db		7h dup(0)
buffer		db		3E80H dup('$')
clrline		db		80 dup(' ')
cif		db		'$'
cifras		db		0
lineaux		db		0


dados	ends


; definicao do segmento de pilha do programa
pilha    segment stack ; permite inicializacao automatica de SS:SP
         dw     128 dup(?)
pilha    ends
         
; definicao do segmento de codigo do programa
codigo   segment ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
inicio:  ; CS e IP sao inicializados com este endereco
         mov    ax,dados ; inicializa DS
         mov    ds,ax    ; com endereco do segmento DADOS
         mov    es,ax    ; idem em ES

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		 
etapa1:
;limpar a tela e receber o nome do arquivo, colocando ou nao ".txt"

; limpa a tela e coloca cursor em (0,0)
	; limpa a tela
    mov     ch,0         ; linha zero  - canto superior esquerdo 
    mov     cl,0         ; coluna zero - da janela
    mov     dh,24        ; linha 24    - canto inferior direito
    mov     dl,79        ; coluna 79   - da janela
    mov     bh,07h       ; atributo de preenchimento (fundo preto e letras cinzas)
    mov     al,0         ; numero de linhas (zero = toda a janela)
    mov     ah,6         ; rola janela para cima
    INT 10H       
	; coloca o cursor em (0,0)
	mov		dh, 0
	mov		dl, 0
	mov		bh, 0
	mov		ah, 2
	INT	10H
;limpa o nome do arquivo na memoria	
	lea 	di, filename
	mov 	cx, 14
limpa_nome:
		mov		[di], byte ptr 0
		inc 	di
		loop limpa_nome
		
	lea 	di, buffer
	mov 	cx, 3E80H
limpa_buffer:
		mov		[di], byte ptr '$'
		inc 	di
		loop limpa_buffer
	
; exibe mensagem pedindo nome do arquivo
	mov		ah, 9
	lea		dx, NomeArq
	INT 21H
	
	mov 	ah, 3
	mov 	bh, 0
	INT 10H				; funcao que devolve a posicao do cursor
	
	mov 	aux, dl			; no dl é o valor da coluna
	mov		nometam, 0
		
; guarda nome do arquivo
	mov		ah, 8	; entrada de caractere sem eco na tela
	INT 21H
		
	lea		di, filename
		
	cmp		al, CR
	jne		naotermina
	jmp		fim			; foi apertado CR para terminar
naotermina:
	cmp		al, BS
	je		le_char	; foi apertado backspace enquanto nao tinha nada escrito
	mov		byte ptr [di], al
	inc		di
	inc		nometam
	
	exibe_char:
	; exibe o caracter na tela	
		mov		dl, al
		mov		ah, 2
		INT 21H
		
	le_char:
		mov		ah, 8	; entrada de caractere sem eco na tela
		INT 21H
		
		cmp		al, CR
		je		fimEtapa1

		cmp		al, BS
		je		backspace
		mov		byte ptr [di], al
		inc		di
		inc		nometam
		
		jmp		exibe_char
		
		backspace:				
			cmp 	di, offset filename		; se ja for o primeiro caractere do nome do arquivo ignora o BS
			je		le_char

			mov		dl, byte ptr BS
			mov		ah, 2			; recua o cursor
			INT 21H
			
			mov		dl, 20h 	; coloca um espaco para ser ecoado na tela
			mov		ah, 2
			INT 21H
			
			mov		dl, byte ptr BS
			mov		ah, 2			; recua o cursor
			INT 21H
			
			dec		di			; reposiciona o lugar de insercao dos caracteres na string
			dec		nometam
			mov		byte ptr [di], 0
			
			jmp		le_char
			
			
fimEtapa1:
	mov		[di], byte ptr 0			; coloca \0 no fim da string
	mov		[di+1], byte ptr '$'		; coloca $ no fim da string para exibicao posterior
	mov		di, offset filename
procuraSufixo:	
	cmp		[di], byte ptr '.'
	je		etapa2
	
	cmp		[di], byte ptr 0
	je		txt
	
	cmp		[di], byte ptr '$'
	je		txt
	
	inc		di
	jmp		procuraSufixo
	
	txt:
		mov		[di], byte ptr '.'
		mov		[di+1], byte ptr 't'
		mov		[di+2], byte ptr 'x'
		mov		[di+3], byte ptr 't'
		mov		[di+4], byte ptr 0
		mov		[di+5], byte ptr '$'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
etapa2:
;abrir arquivo. Se erro, mostrar msg e voltar para a etapa 1
	mov		ah,3DH
	mov		al, 0			; 0 para modo leitura
	lea		dx, filename
	INT	21H
	jc 		erro_abertura
	
	mov		handler, ax
	jmp		etapa3

	erro_abertura:
	; exibe mensagem de erro e volta para a etapa 1
		mov		ah, 9
		lea		dx, msgERROab
		INT	21H
		
		cmp 	al, 2
		je 		erro_encontrado
		cmp 	al, 4
		je 		erro_handler			;testa se o erro foi falta de handlers
		cmp 	al, 3
		je 		erro_caminho			;testa se o erro foi caminho inexistente
		cmp 	al, 5
		je 		erro_acesso			;testa se o erro foi acesso negado
		
		jmp 	etapa1
		
		erro_encontrado:
		lea 	dx, erroAB1
		jmp exibe_erro
		
		erro_handler:
		lea 	dx, erroAB2
		jmp exibe_erro
		
		erro_caminho:
		lea 	dx, erroAB3
		jmp exibe_erro
		
		erro_acesso:
		lea 	dx, erroAB4
								
		exibe_erro:
		mov 	ah, 9
		int 21h					;exibe mensagens de erro de acordo com o teste
		
		; espera tecla
		mov    ah,0               
		INT 16H				
		jmp etapa1
		
	;Se CF=1, AX: código de erro
		;01: função inválida	04: não há mais handlers disponíveis
		;02: arquivo não encontrado	05: acesso negado
		;03: caminho não encontrado	06: modo de acesso inválido


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
etapa3:
;limpar tela e deixar a primeira e ultima linhas coloridinhas

; coloca o cursor em (0,0)
	mov		bh, 0
	mov		dh, 0
	mov		dl, 0
	mov		ah, 2
	INT	10H

; limpa a tela
    mov     ch,0         ; linha zero  - canto superior esquerdo 
    mov     cl,0         ; coluna zero - da janela
    mov     dh,24        ; linha 24    - canto inferior direito
    mov     dl,79        ; coluna 79   - da janela
    mov     bh,07h       ; atributo de preenchimento (fundo preto e letras cinzas)
    mov     al,0         ; numero de linhas (zero = toda a janela)
    mov     ah,6         ; rola janela para cima
    INT	10H 
	
; pinta de verde	
	mov 	ah,9
	mov 	cx,80
	mov 	bl,2EH
	mov		al, 20H
	mov 	bh, 0
	INT 10H

; coloca o cursor em (0,24)
	mov		bh, 0
	mov		dh, 24
	mov		dl, 0		
	mov		ah, 2
	INT	10H
; pinta de verde	
	mov 	ah,9
	mov 	cx,80
	mov 	bl,2EH
	mov		al, 20h
	mov 	bh, 0
	INT 10H

; transformar lidos e eliminados em string
;	mov		dx, word ptr 0
;	mov		ax, lidos
;	lea		di, strLidos
;	call	intostr
	
;	mov		dx, word ptr 0
;	mov		ax, eliminados
;	lea		di, strElim
;	call	intostr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
etapa4:
; ler arquivo, tirar espacos duplos e TABs, contar numero de caracteres lidos e eliminados e exibir
	mov 	ah, 3FH
	mov 	bx, handler
	mov 	cx, 3E80H	; 16000
	lea 	dx, buffer
	INT 21H
	jnc  	sem_erro

	erro_leitura:
	; exibe mensagem de erro e volta para a etapa 1
		mov		ah, 9
		lea		dx, msgERROle
		INT	21H
	
		; espera tecla
		mov    ah, 0               
		INT 16H				
		jmp etapa1
	
sem_erro:
	mov		lidos, ax
; fecha arquivo

    mov 	ah, 3eh
    mov 	bx, handler
    INT 21H
	
	mov		eliminados, 0
	
	lea		di, buffer
	add		di, lidos
	
	lea		si, buffer
	lea		di, buffer

	mov		cx, lidos
	cld
remove:
	lodsb
	
	cmp 	al, TAB
	je		removeTAB
	cmp 	al, 32
	je		ESduplo
	
	jmp		salva
	
	removeTAB:
		inc		eliminados
		jmp		naoSalva	
	ESduplo:
		cmp		[di-1], byte ptr 32
		jne		salva
		inc		eliminados
		jmp		naoSalva
		
salva:
	stosb		
naoSalva:	
	loop	remove
	
	mov		[di], byte ptr 0
	mov		[di+1], byte ptr '$'
	
	
; coloca o cursor em (0,0)
	mov		dh, 0
	mov		dl, 0
	mov		bh, 0
	mov		ah, 2
	INT	10H
	
	mov		ah, 9
	lea		dx, cabecalho1
	INT	21H
	
	mov		ah, 9
	lea		dx, filename
	INT	21H
	
	mov		ah, 9
	lea		dx, cabecalho2
	INT	21H
	
	; transforma lidos em string
	mov		ax, lidos
	lea		di, strLidos
	mov		dx, 0
	mov 	[di], byte ptr '1'
	cmp 	ax, 9999
	ja 		m10k_lidos
	mov 	[di], byte ptr '0'

m10k_lidos:	
	mov		[di+6], byte ptr '$'
	
	mov		dez, word ptr 10
	div		dez
	add		dx, 48
	mov		[di+5], dl

	mov 	dx, 0
	div		dez
	add		dl, 48
	mov		[di+4], dl

	mov 	dx, 0
	div		dez
	add		dx, 48
	mov		[di+3], dl
	
	mov		[di+2], byte ptr '.'

	mov 	dx, 0
	div		dez
	add		dx, 48
	mov		[di+1], dl

; imprime a parir do digito significativo	
	cmp		[di], byte ptr '0'			; dezena de milhar
	jne		imprime_lidos		
	inc		di
	cmp		[di], byte ptr '0'			; milhar e ponto
	jne		imprime_lidos
	add		di, 2				; pula o .
	cmp		[di], byte ptr '0'			; centena
	jne		imprime_lidos
	inc		di
	cmp		[di], byte ptr '0'			; dezena
	jne		imprime_lidos
	inc		di

imprime_lidos:
	mov		ah, 9
	mov		dx, di
	INT	21H
	
	mov		ah, 9
	lea		dx, cabecalho3
	INT	21H

; transforma eliminados em string 
	mov		ax, eliminados
	lea		di, strElim
	mov		dx, 0
	mov 	[di], byte ptr '1'
	cmp 	ax, 9999
	ja 		m10k_lidos
	mov 	[di], byte ptr '0'

m10k_eliminados:	
	mov		[di+6], byte ptr '$'
	
	mov		dez, word ptr 10
	div		dez
	add		dx, 48
	mov		[di+5], dl

	mov 	dx, 0
	div		dez
	add		dl, 48
	mov		[di+4], dl

	mov 	dx, 0
	div		dez
	add		dx, 48
	mov		[di+3], dl
	
	mov		[di+2], byte ptr '.'

	mov 	dx, 0
	div		dez
	add		dx, 48
	mov		[di+1], dl

; imprime a parir do digito significativo	
	cmp		[di], byte ptr '0'			; dezena de milhar
	jne		imprime_eliminados		
	inc		di
	cmp		[di], byte ptr '0'			; milhar e ponto
	jne		imprime_eliminados
	add		di, 2						; pula o .
	cmp		[di], byte ptr '0'			; centena
	jne		imprime_eliminados
	inc		di
	cmp		[di], byte ptr '0'			; dezena
	jne		imprime_eliminados
	inc		di

imprime_eliminados:
	mov		ah, 9
	mov		dx, di
	INT	21H

	mov		ah, 9
	lea		dx, cabecalho4
	INT	21H
	
	; coloca o cursor em (0,24)
	mov		dh, 24
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H
	
	mov		ah, 9
	lea		dx, msgESC
	INT	21H
	
;	jmp		etapa5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
etapa5:
;exibir o texto na tela com as quebras de linha

	mov		cifras, 0
	mov		linha, 1
	mov		aux, 81
	lea		di, buffer
	lea		si, buffer
	
quebraLinha:
	dec		aux	
	cmp		[di], byte ptr 10 
	jne		ignoraLF
	inc		di
ignoraLF:
	cmp		[di], byte ptr 0
	je		imprimeUltimaLinha
	cmp		[di], byte ptr 32 
	je		salvaES
	cmp		[di], byte ptr 13
	je		resetaCR
	jmp		continuaES
	
	salvaES:
		; call ola1
		; call pausa
	
		mov		ptaux, di
		jmp		continuaES
	resetaCR:
		; call ola2
		; call pausa
		
		mov		aux, 81
		inc		di			; pula LF
		jmp 	exibe
;
continuaES:		
	inc		di
	cmp 	aux, 0
	jne		quebraLinha
	
	mov		di, ptaux
	cmp		[di], byte ptr 32
	jne 	deuRuim

exibe:	
	mov		[di], byte ptr '$'
	inc		cifras
	inc		di
	
	cmp		linha, 24
	jae		naoImprime
	
	mov		dh, linha
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H
	
	mov		ah, 9
	mov		dx, si
	INT	21H
naoImprime:
	mov		aux, 81
	mov		si, di
	inc 	linha
	
	jmp quebraLinha

deuRuim:
	dec		di
	cmp		[di], byte ptr 32
	jne 	deuRuim
	jmp 	exibe
	
imprimeUltimaLinha:
	mov		[di+1], byte ptr '$'
	inc		cifras
	
	mov		dh, linha
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H
	
	mov		ah, 9
	mov		dx, si
	INT	21H
	
	
;;;;	
	mov		dh, 24
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H
	
	mov		ah, 9
	lea		dx, msgESC
	INT	21H
;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
etapa6:
; rolagem
	mov		lineaux, 0
	
	mov		dh, 24
	mov		dl, 79
	mov		bh, 0		
	mov		ah, 2
	INT	10H
	
	cmp		cifras, 23
	jbe		esperaESC		

esperaTecla:
	mov		ah, 8	; entrada de caractere sem eco na tela
	INT 21H
	
	cmp		al, 'w'
	je		sobe
	cmp		al, 'W'
	je		sobe
	cmp		al, 's'
	je		desce
	cmp		al, 'S'
	je		desce
	
	cmp		al, ESCAPE
	jne		esperaTecla
	jmp		etapa1
	
esperaESC:
	mov		ah, 8	; entrada de caractere sem eco na tela
	INT 21H
	cmp		al, ESCAPE
	jne		esperaESC
	jmp		etapa1

sobe:
	cmp 	lineaux, 0
	jbe 	esperaTecla					; ignora se ja for a primeira linha
	dec		lineaux
	jmp		rolaTela
desce:
	mov		ah, lineaux
	add		ah, 24
	cmp		ah, cifras
	je		esperaTecla
	inc		lineaux
	jmp		rolaTela

rolaTela:
	mov		linha, 1
	mov		al, 0			; numero de cifras encontradas
	lea		di, buffer
	lea		si, buffer
	
	procuraInicio:
		cmp		[di], byte ptr '$'
		je		testaInicio
		inc		di
		jmp		procuraInicio
		
		testaInicio:
			cmp		al, lineaux
			je		imprime
			inc		di
			mov		si, di
			inc		al
			jmp		procuraInicio
imprime:			
; posiciona cursor na primeira linha	
	mov		dh, linha
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H		
; limpa lixo da linha	
	mov		ah, 9
	lea		dx, clrline
	INT	21H
	
	mov		dh, linha
	mov		dl, 0
	mov		bh, 0		
	mov		ah, 2
	INT	10H	
	
	mov		ah, 9
	mov		dx, si
	INT	21H
	
		procuraFim:
		cmp		[di], byte ptr '$'
		je		testaFim
		inc		di
		jmp		procuraFim
		
		testaFim:
			inc		di
			mov		si, di
;	
	inc		linha
	cmp		linha, byte ptr 24
	jne     imprime
	jmp 	esperaTecla
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
fim:
;exibe mesagem de fim e termina
	mov		aux, 24
pinta:
	mov		bh, 0
	mov		dh, aux
	mov		dl, 0
	mov		ah, 2
	INT	10H
	
	mov 	ah,9
	mov 	cx,79
	mov 	bl,0DH		; atributo rosinha
	mov		al, 20h
	mov 	bh, 0
	INT 10H
	
	dec 	aux
	cmp		aux, -1
	jne		pinta
	
	mov		ah, 9
	lea		dx, msgFim
	INT	21H
	
	mov		bh, 0
	mov		dh, 24
	mov		dl, 0
	mov		ah, 2
	INT	10H

; espera tecla
    mov    ah,0               
    INT 16H

    mov    ax,4c00h           ; funcao retornar ao DOS no AH
    int    21h 
	
codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve começar a execucao no rotulo "inicio"
         end    inicio 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
