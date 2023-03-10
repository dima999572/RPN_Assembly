org 100h

start:

	; Moj program sklada sie z dwoch czesci
	; 1 - konwersja wpisaniego wyrazu w postac ONP
	; 2 - obliczenie wyrazu matematycznego, ktory ma postac ONP

	call ent ; Dwa entera dla piekna
	call ent
	call onp ; Konwertuje wpisany wyraz w ONP
	call ob_onp ; Oblicza wyraz ONP
	call ent ; Enter dla piekna
	
	call koniec

intro db "Napisz matematyczny wyraz, maksymalnie 25 symboli. "	
	  db 10, 13
	  db "Mozna wpisywac cyfry oraz +,-,*,/: $"
	   
wo_t db 10,13, "Wyrazenie w postaci ONP: $" ; wyraz onp text

w_t db 10,13, "Wynik: $"; wynik text
		
blad_1 db 10,13, "Error message. Nieprawidlowo napisales nawiasy. $"

blad_2 db 10,13, "Error message. Napisales nieprawidlowy znak. $"	

blad_3 db 10,13, "Error message. Pierwszy sybol w wyrazie matematycznym operator. $"

blad_4 db 10,13, "Error message. Niezgodna ilosc liczb i operatorow. $"

blad_5 db 10,13, "Error message. Blad dzielienia przez 0. $"

; Blad 6 nie zdazylem obsluzyc
blad_6 db 10,13, "Error message. W wyniku dodawania/odejmowania przektoczono mozliwy zakres wartosci 16 bitow. $"

expr db 26 ; math expression
	 db 0
	 times 27 db 36
	  
end_expr times 100 db 36 ; end math expression 
	     db 36

ile db 0 ; zmienna do obliczania, ile bedzie symboli w wyrazie onp

liczba times 10 db 36 ; czasowa zmienna, ktora jest uzywana dla zapisu liczb dwucyfrowych i wiecej

wynik times 20 db 36 ; koncowy wynik

onp:
	pusha
	pushf
		
		mov ah,9
		mov dx,intro ; wypisywanie intra
		int 21h
		
		mov ah,10
		mov dx,expr ; wpisywanie wyrazu matematycznego
		int 21h
		
		mov cl,[expr+1] ; licznik main petli
		mov ch,0 ; pomoc na stosie
		mov si,expr+2 ; to jest adres na wyraz matematyczny, ktory wpisalismy
		mov di,end_expr ; adres na pusta zmienna, w ktorej potem bedzie skonwertowane wyrazenie matematyczne w postaci ONP
		
		mov ah,0 ; ah = 0 - wczesniej byl‚a cyfra, ah = 1 - wczesniej byl‚ znak. UZYWAMY DLA SPACJI
		mov bx,0 ; bh - ilosc znakow arytmietycznych, bl - ilosc cyfr. UZYWAMY DLA ZNALEZNIENIA BLADOW
		
		main:	
			
			; Tu jest porownywanie znaku ktory lezy pod adresem rejestru si z roznymi symbolami i rzucanie
			; nas do roznych etykiet
			
			cmp [si],byte 40 ; (
			je throw_1
			
			cmp [si],byte 41 ; )
			je throw_2
			
			cmp [si],byte 42 ; *
			je throw_31
			
			cmp [si],byte 43 ; +
			je throw_32
			
			cmp [si],byte 45 ; -
			je throw_32
			
			cmp [si],byte 47 ; /
			je throw_31
			
			cmp [si],byte 48 ; 0
			jl blad_z
			
			cmp [si],byte 57 ; 9
			jg blad_z
			
			jmp throw_4 ; to znaczy, ze mamy cyfre
			
			; Rzucanie nawiasu na stos
			throw_1:
				mov dl,[si]
				xor dh,dh
				push dx
				inc ch
				jmp end_2
				
			; Zewnetrzna etykieta sprawdza czy mamy pusty stos, jezli tak, to nawias 
			; zamykajacy nie moze istniec w danym miejscu w wyrazeniu matematycznym
			; wiec mamy blad
			throw_2:
				cmp ch,0
				je blad_n ; blad nawias
				mov ah,1
				
				; Zrzucamy elementy ze stosu dopoki nie otrzymamy
				; nawias otwierajacy, jesli zrobilismy pop wszystkich operatorow 
				; i nie doszlismy do nawaisu otwierajacego mozliwy jest blad
				; co sprawdzamy w etykiecie sprawdz
				dn: ; dalej nawiasy
					cmp ch,0
					je sprawdz
					
					dec ch
					
					pop dx
					cmp dl,40 ; (
					je end_2
					
					mov [di],byte 32 ; space
					inc di
					add [ile],byte 2
					mov [di],dl
					inc di					
					cmp bl,40
					jne dn
					
					sprawdz:
						pop dx
						cmp dl,40 ; (
						jne blad_n
						jmp end_2
					
			; To przypadek, kiedy we wpisanej zmiennej natknolismy na znak mnozenia lub dzielenia
			; Po pierwsze sprawdzam czy operator nie zostal wpisany na pierwszym miejscu wyrazenia
			; jesli tak - to prawdopodobnie to jest blad
			throw_31: ; *, /
				inc bh
				cmp si,expr+2
				jne po_31
			
				cmp ch,0
				je blad_c
				
				; Idziemy tu, jesli wszystko w porzadku i nie ma zadnego bladu
				; Jesli operator ktory na gorze stosu jest wiekszym lub rownym w pryorytecie od 
				; operatora mnozenia lub dzielenia, to zrzucamy ten element ze stosu i wpisujemy
				; go do naszego zmienniej ktora przechowuje wyraz ONP
				; W innym przypadku skakujemy do etykiety throw_1, bo nam jest potrzebne dzialanie
				; ktore zawsze uzywa sie przy spotkaniu nawiasow otwierajacych
				po_31:
					mov ah,1
					mov bp,sp

					cmp ch,0
					je throw_1
		
					cmp [bp],byte 40 ; (
					je throw_1
					
					cmp [bp], byte 43 ; +
					je throw_1
					
					cmp [bp], byte 45 ; -
					je throw_1
					
					cmp [bp], byte 42 ; *
					je zdejmij
					
					cmp [bp], byte 47 ; /
					je zdejmij
				
			; Tutaj dziala podobnie do mnozenia i dzielenia, tylko jeden operator
			; ktory ma nizszy pryorytet od plusa i minusa - to nawias otwierajacy
			throw_32: ; +, -
				inc bh
				cmp si,expr+2
				jne po_32
				
				cmp ch,0
				jmp blad_c
				
				po_32:
					mov ah,1
					
					cmp ch,0
					je throw_1
					
					mov bp,sp
					
					cmp [bp],byte 40 ; (
					je throw_1
					
					cmp [bp],byte 42 ; *
					je zdejmij
					
					cmp [bp],byte 43 ; +
					je zdejmij
					
					cmp [bp],byte 45 ; -
					je zdejmij
					
					cmp [bp],byte 47 ; /
					je zdejmij
					
					; Tu jest zdejmowanie operatorow ze stosu po zasadach, ktore opisalem wyzej
					; W koncu jest sprawdzenie elementu, ktore lezy pod adresem rejestru si
					; i rzuca nas do odpowiednich etykiet po
					zdejmij: ; dla * oraz /
						mov bp,sp
						
						cmp [bp],byte 40 ; (
						je throw_1
							
						cmp ch,0
						je throw_1
							
						dec ch
						
						mov [di],byte 32 ; spacja
						inc di
						add [ile],byte 2
						
						pop dx
						mov [di],dl
						inc di
						
						cmp [si],byte 42 ; *
						je po_31
						cmp [si],byte 47 ; /
						je po_31
						
						jmp po_32
				
			; To jest przypadek, w ktorem pod adresem rejestru si lezy jakas cyfra
			; Na poczatku mamy sprawdzenie naszej wlasnej flagi w rejestrze ah, jesli rejestr ah
			; jest rowny zeru, to znaczy ze wczesniej mielismy nic(poczatek wyrazu), lub
			; cyfre i musimy zapisac je razem, bez spacju. 
			; Etykieta bez dziala odwrotnie
			throw_4:
				cmp ah,0
				mov ah,0
				je bez
	
				; movsb - wartosc ktora jest zapisana pod adresem rejestru si 
				; wpisuje do wartosci ktora jest zapisana pod adresem rejestru di
				; oraz inkrementuje oba rejestry(si oraz di)
				ze: ; ze spacja
					inc bl
					add [ile], byte 2
					mov [di],byte 32
						inc di
					movsb
					jmp end_1
				
				bez: ; bez spacji
					inc byte [ile]
					movsb
					jmp end_1
				
			; Tu sprawdzamy czy mamy koniec zmiennej wpisanej 
			; jesli tak - idziemy w koniec
			; Etykieta end_1 jest uzywana tylko w przypadku kiedy mamy cyfre
			; bo za pomoca movsb mamy automatyczna iknrementacje rejestru si
			end_1:
				dec cl
				cmp cl,0
				jne main
				jmp kon_1
			end_2:
				inc si ; si na nastepnym znakie	
				dec cl
				cmp cl,0
				jne main
				jmp kon_1
		
		; Kilka bladow ktore moga wystapic przy konwertacji wyrazenia
		; do postaci ONP
		blad_n: ; blad nawiasy
			mov ah,9
			mov dx,blad_1
			int 21h
			jmp koniec
			
		blad_z: ; blad znak
			mov ah,9
			mov dx,blad_2
			int 21h
			jmp koniec

		blad_c: ; blad cyfra
			mov ah,9
			mov dx,blad_3
			int 21h
			jmp koniec
			
		blad_i: ; blad ilosc
			mov ah,9
			mov dx,blad_4
			int 21h
			jmp koniec
			
		; W koncu 1 zrzucamy wszystkie operatory, jesli takie sa
		; Takze tu moze wystepowac blad jesli na stosie bedie nawias otwierajacy
		kon_1: ; koniec 1
			cmp ch,0
			je kon_2
			
			mov [di],byte 32 ; spacja
			inc di
			add [ile],byte 2
			
			pop dx
			cmp dl,byte 40 ; (
			je blad_n
			mov [di],dl
			
			inc di
			dec ch
			jmp kon_1
			
		; W koncu 2 sprawdzamy na blad , kiedy jest wpisana 1 liczba, oraz
		; jesli ilosc liczb nie jest rowna liczbe operatorow(bez '(' oraz ')') minus jeden
		kon_2: ; koniec 2
			cmp bl,bh
			jne blad_i
			cmp bl,0
			je blad_i
			
		; No i tu mamy piekne wyswietlienie naszego wyniku
		mov ah,9
		mov dx,wo_t
		int 21h
			
		mov ah,9
		mov dx,end_expr
		int 21h
	
	popf
	popa
ret

ob_onp: ; oblicz onp
	pusha
	pushf

		mov cl,0 ; licznik dla konwejrsji string w int
		mov si,end_expr
		
		licz:
		
			; Tu jest porownywanie znaku ktory lezy pod adresem rejestru si z roznymi symbolami i rzucanie
			; nas do roznych etykiet
		
			cmp [si],byte 32 ; spacja
			je kon_3
			
			cmp [si],byte 42 ; *
			je policz
			
			cmp [si],byte 43 ; +
			je policz
			
			cmp [si],byte 45 ; -
			je policz
			
			cmp [si],byte 47 ; /
			je policz
			
			mov di,liczba
			jmp nlicz_1
			
			; Tu jest zrzucanie ze stosu dwoch liczb, rzucanie ich do stosu koprocesora no ich
			; rzucanie do odpowiedniej etykiety, to znaczy mnozenia, dodawanie, odejmowania
			; lub dzielenia dwoch liczb
			policz:
			
				pop ax
				mov [bp],ax ; b
				fild word [bp]
				
				pop ax
				mov [bp],ax ; a
				fild word [bp]
				
				cmp [si],byte 42 ; *
				je mnoz
			
				cmp [si],byte 43 ; +
				je dodaj
			
				cmp [si],byte 45 ; -
				je odejmij
			
				cmp [si],byte 47 ; /
				je dziel	
			
			nlicz_1:
				; Przypisujemy do zmiennej czasowej "liczba" luczby, ktora lezy 
				; w wyrazie ONP
				movsb ; from si to di and inc si and di
				dec byte [ile]
				inc cl
				cmp [si],byte 32 ; spacja
				
				je nlicz_2
				jmp nlicz_1
				
				nlicz_2:
					; Tutaj rzucamy na koprocesor 10 i 1, dla konwersci otrzymania jedynek, dzisatek,
					; setek i td liczb, takze dajemy miejsce dla tej liczby na stosie
					xor ax,ax
					push ax
							
					mov al,10
					mov bp,sp
					mov [bp], ax
					fild word [bp]
					
					mov al,1
					mov bp,sp
					mov [bp], ax
					fild word [bp]
					
					xor ax,ax
					mov bp,sp
					mov [bp],byte 0
					
					; Tu wrzystkie dzialania, dla opisu tego bedzie przyklad
					; LICZBA MNOZACA - 1, LICZBA POMOCNICZA - 10
					; Mamy 123, na paczatku bierzmy 3, mnozymy go razy 1, to jest 3 - mamy jedynki
					; Dalej 1 mnozymy razy 10 - LICZBA MNOZACA = 10
					; Bierzmy 2 mnozymy razy 10, to jest 20 - mamy dziesiatki
					; Dalej 10 mnozymy razy 10 - LICZBA MNOZACA = 100
					; Bierzmy 1 mnozymy razy 100, to jest 100 - mamy setki
					; Wszystko skladamy i mamy 3+20+100=123 - nasza liczba
					; PO PRZECZYTANIU OPISU TEGO SCHEMATU SPRAWDZENIE TEJ ETYKIETY NIE JEST TRUDNE
					nlicz_3: ; nie licz
						dec cl
						dec di
						
						xor dh,dh
						mov dl,byte [di]
						sub dl,48
						mov [bp],dx
						
						fild word [bp]
						fmul st0,st1 ; st0=st0*st1
						fistp word [bp] ; zrzucamy wynik do [bp] 
						fmul st0,st1
						
						add ax,[bp] ; dodajemy wynik kolejowy(jedynki, dziesiatki, setki i td) do 
						; wyniku koncowego(cala liczba)
						
						cmp cl,0
						jne nlicz_3
						fistp word [bx]
						fistp word [bx] ; czyscim stos coprocessora
						mov [bp],ax
						jmp kon_4
			
			; Etykiety mnoz, dodaj, odejmij takie same, beda mieli jeden opisalem
			; Mnozymy(na przyklad) dwie liczby, ktore sa na stosie koprocesora,
			; zrzucamy wynik mnozenia, i rzucamy go na stos zwykly, czyscim
			; stos koprocesora
			mnoz: ; mnozenie
				fmul st0,st1
				fistp word [bx]				
				mov ax,[bx]
				push ax
				fistp word [bx]
				jmp kon_3
			
			dodaj: ; dodawanie
				fadd st0,st1	
				fistp word [bx]
				mov ax,[bx]
				push ax
				fistp word [bx]
				jmp kon_3
				
			odejmij: ; odejmowanie
				fsub st0,st1
				fistp word [bx]				
				mov ax,[bx]
				push ax
				fistp word [bx]
				jmp kon_3
				
			; Tu jescze jest sprawdzenie warunki, czy liczba na ktora 
			; dzielimy nie jest zerem, jesli jest - blad
			dziel: ; dzielienie
				mov [bp],byte 0
				fild word [bp]
				fcom st0,st2
				je zer_blad ; zero blad
				fistp word [bx]
				
				fdiv st0,st1
				fistp word [bx]				
				mov ax,[bx]
				push ax
				fistp word [bx]
				jmp kon_3	
			
			; Te konce sa podobne, koniec 4 uzywamy dla przypadku, kiedy wrzucilicmy liczbe
			; na stos, w takim przypadku juz mamy zainkrementowane si(movsb) oraz 
			; zadekrementowane [ile]
			kon_3: ; koniec 3
				inc si
				dec byte [ile]
				cmp [ile],byte 0
				jne licz
				jmp dalej
			kon_4: ; koniec 4
				cmp [ile],byte 0
				jne licz
				jmp dalej
				
			; Kilka bladow ktore moga wystapic przy obliczaniu
			; wyrazenia w postaci ONP	
			zer_blad:
				mov ah,9
				mov dx,blad_5
				int 21h
				jmp koniec
				
			c_blad:
				mov ah,9
				mov dx,blad_6
				int 21h
				jmp koniec
				
			dalej:
				; Tu jest sprawdzenie czy liczba jest dodatnia lub ujemna, 
				; w przypadku liczby dodatnie robimy dodawanie dziesietne,
				; z kolei w przypadku liczby ujemnej do wyniku koncowego 
				; dodajemy minusa, oraz robimy negacje liczby ujemnej.
				; To jest przypadek z U2
				pop ax
				mov ch,0
				mov bx,10
				mov di,wynik
				
				cmp ax,0
				jl min
				jmp d_dzies
				
				min: ; minus, przypisanie minusa do wynika koncowego
					mov [di],byte 45
					inc di
					neg ax
				
				d_dzies: ; dodaj dziesietnie
					loop_1:
						xor bh,bh 
						xor dx,dx
						div bx 
						push dx ; ; reszta w DX ; dx = ax / bx
						
						inc ch ; 1	
									
						cmp ax,0 ; 54
						jne loop_1
			
					loop_2:				
						xor dx,dx
						pop dx
						add dx,48
						
						mov [di],dl
						inc di
						
						dec ch
						cmp ch,0
						jnz loop_2
				
		; Tu robimy piekne wyswietlienie naszego wyniku
		mov ah,9
		mov dx,w_t
		int 21h
		
		mov ah,9
		mov dx,wynik
		int 21h

	popf
	popa
ret

ent:
	pusha
	
		mov ah,2
		mov dl,10
		int 21h
		
		mov ah,2
		mov dl,13
		int 21h
	
	popa
ret

koniec:
	mov ax, 4C00h
	int 21h
