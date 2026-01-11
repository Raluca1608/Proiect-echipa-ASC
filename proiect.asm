ASSUME cs:code, ds:data              ; Spunem asamblorului ce segmente folosim pentru CS si DS

data SEGMENT                         ; Incepe segmentul de date
    msj_intro db 'Indroduceti octetii in format hex (intre 8 si 16 valori): $' ; Mesaj introducere (terminat cu $)
    msj_eroare db 13, 10, 'Input invalid / numar de valori invalid(8 - 16 valori).', 13, 10, '$' ; Mesaj eroare + newline
    msj_C   db 13, 10, 'Cuvantul C calculat: $' ; Mesaj pentru afisarea lui C
    msj_rot  db 13,10,'Sirul dupa rotiri (BIN HEX):',13,10,'$' ; Mesaj pentru afisare rotiri
    hex_tbl db '0123456789ABCDEF'    ; Tabel cu cifre hex (0..F)
    bufC    db '0000','$'            ; Buffer pentru afisare (hex sau bin), terminat cu $
    sir_introdus db 50, ?, 50 dup(?) ; Buffer DOS pentru citire (AH=0Ah): max=50, len=?, date...
    octeti db 16 dup(0)              ; Vector de max 16 octeti convertiti
    nocteti db 0                     ; Numarul de octeti cititi (0..16)
    C dw ?                           ; Variabila word pentru C
    msj_poz db 13,10,'Pozitia octetului cu cei mai multi biti 1: $' ; Mesaj pozitie maxim biti 1
    max_bits db 0                    ; Maximul de biti 1 gasit
    poz_max  db 0                    ; Pozitia (index) la care apare maximul
    tmp_rot db 0                     ; Variabila temporara pentru octetul rotit
data ENDS                            ; Sfarsit segment date

code SEGMENT                         ; Incepe segmentul de cod
start:                               ; Punctul de start al programului
    ; initializam segmentul de date
    mov ax, data                     ; AX = adresa segmentului de date
    mov ds, ax                       ; DS = segmentul de date

;============================================================
;CITIRE, CONVERTIRE DIN ASCII IN VALORI BINARE, STOCARE 
;============================================================
citire:                              ; Eticheta: reluam citirea de la tastatura
    ; afisare mesaj de introducere
    mov ah, 09h                      ; Functie DOS: afisare sir terminat cu $
    lea dx, msj_intro                ; DX = adresa mesajului
    int 21h                          ; Apel DOS

    ;citire sir de la tastatura
    mov ah, 0Ah                      ; Functie DOS: citire bufferata
    lea dx, sir_introdus             ; DX = adresa bufferului
    int 21h                          ; Apel DOS

    ; initializari
    mov nocteti, 0                   ; Resetam numarul de octeti cititi
    mov si, offset sir_introdus      ; SI = inceput buffer
    add si, 2                        ; Sarim peste (maxlen, len) -> incepe textul introdus
    mov cl, [sir_introdus + 1]       ; CL = numarul de caractere citite
    mov ch, 0                        ; CX = numarul de caractere (CH=0)
    mov di, offset octeti            ; DI = unde vom salva octetii convertiti

    jmp conversie_octeti_hexa        ; Mergem la conversie

input_gresit:                        ; Eticheta pentru input invalid
    ; la orice greseala de introducere se afiseaza eroare si se reface citirea
    mov ah, 09h                      ; Afisare sir $
    lea dx, msj_eroare               ; DX = mesaj eroare
    int 21h                          ; Apel DOS
    jmp citire                       ; Reincercam citirea

conversie_octeti_hexa:               ; Convertim textul in octeti binari
    cmp cx, 0                        ; Verificam daca mai sunt caractere
    je conversie_finalizata          ; Daca nu, iesim din conversie

sarim_spatiu:                        ; Sarim peste spatii
    cmp cx, 0                        ; Daca nu mai avem caractere
    je conversie_finalizata          ; Terminam
    cmp byte ptr [si],' '            ; Verificam daca e spatiu
    jne cifra1                       ; Daca nu, urmeaza prima cifra hex
    inc si                           ; Trecem peste spatiu
    dec cx                           ; Scadem din numarul de caractere ramase
    jmp sarim_spatiu                 ; Continuam sa sarim spatiile

cifra1:                              ; Citim prima cifra hex (high nibble)
    mov al, [si]                     ; AL = caracterul curent
    cmp al, '9'                      ; E intre '0' si '9'?
    jbe cifra1_numar                 ; Daca da, ramura pentru cifra
    cmp al, 'A'                      ; Daca e mai mic decat 'A'
    jb input_gresit                  ; E invalid
    cmp al, 'F'                      ; Daca e mai mare decat 'F'
    ja input_gresit                  ; E invalid
    sub al, 'A' - 10                 ; Convertim 'A'..'F' -> 10..15
    jmp cifra1_corecta               ; Continuam

cifra1_numar:                        ; Ramura cand e cifra '0'..'9'
    ; transformam din ASCII in valori efective
    cmp al, '0'                      ; Daca e sub '0'
    jb input_gresit                  ; Invalid
    sub al, '0'                      ; Convertim '0'..'9' -> 0..9

cifra1_corecta:                      ; AL contine valoarea 0..15
    shl al, 4                        ; Mutam in nibble-ul superior (x16)
    mov bl, al                       ; BL pastreaza high nibble (xxxx0000)

    inc si                           ; Trecem la urmatorul caracter
    dec cx                           ; Un caracter consumat
    cmp cx, 0                        ; Daca nu mai exista alt caracter
    je input_gresit                  ; E invalid (lipsea cifra2)

cifra2:                              ; Citim a doua cifra hex (low nibble)
    mov al, [si]                     ; AL = al doilea caracter
    cmp al, '9'                      ; E cifra?
    jbe cifra2_numar                 ; Daca da
    cmp al, 'A'                      ; Daca e sub 'A'
    jb input_gresit                  ; Invalid
    cmp al, 'F'                      ; Daca e peste 'F'
    ja input_gresit                  ; Invalid
    sub al, 'A' - 10                 ; 'A'..'F' -> 10..15
    jmp cifra2_corecta               ; Continuam

cifra2_numar:                        ; Daca e cifra '0'..'9'
    ; transformam din ASCII in valori efective
    cmp al, '0'                      ; Sub '0'?
    jb input_gresit                  ; Invalid
    sub al, '0'                      ; Convertim in 0..9

cifra2_corecta:                      ; AL = low nibble (0..15), BL = high nibble
    or al, bl                        ; Combinam nibble-uri -> octet complet
    mov [di], al                     ; Salvam octetul in vector
    inc di                           ; Avansam la urmatoarea pozitie din vector

    mov al, nocteti                  ; AL = numarul curent de octeti
    inc al                           ; AL++
    mov nocteti, al                  ; Salvam noul numar
    cmp al, 16                       ; Depasim 16?
    ja input_gresit                  ; Daca da, invalid (prea multi)

    inc si                           ; Trecem dupa cifra2
    dec cx                           ; Scadem un caracter

    cmp cx, 0                        ; Daca nu mai sunt caractere
    je conversie_finalizata          ; Terminam conversia

    cmp byte ptr [si], ' '           ; Dupa un octet asteptam spatiu
    jne input_gresit                 ; Daca nu e spatiu -> format gresit
    jmp sarim_spatiu                 ; Sarim spatiile si continuam

conversie_finalizata:                ; Aici am terminat conversia
    mov al, nocteti                  ; AL = total octeti

    cmp al, 8                        ; Minim 8?
    jae ok_min                       ; Daca da, ok
    jmp input_gresit                 ; Daca nu, invalid
    ok_min:                          ; Eticheta: minim respectat

    cmp al, 16                       ; Maxim 16?
    jbe ok_max                       ; Daca da, ok
    jmp input_gresit                 ; Daca nu, invalid
    ok_max:                          ; Eticheta: maxim respectat

;============================================================
;CALCULAREA CUVANTULUI C 
;============================================================

    mov al, [octeti]                 ; AL = primul octet

    xor bh, bh                       ; BH = 0 (pregatim BX)
    mov bl, nocteti                  ; BL = nr octeti
    dec bl                           ; BL = (n-1) pentru indexul ultimului element
    mov ah, [octeti + bx]            ; AH = ultimul octet

    and al, 0F0H                     ; Pastram nibble-ul superior al primului
    shr al, 4                        ; Il aducem jos -> AL = bits 0..3

    and ah, 0Fh                      ; Pastram nibble-ul inferior al ultimului

    xor al, ah                       ; XOR intre cele doua nibble-uri
    mov dl, al                       ; DL = bits 0..3 din C

    xor bl, bl                       ; BL = 0 (acumulator pentru OR)
    xor ch, ch                       ; CH = 0
    mov cl, nocteti                  ; CL = nr octeti
    mov si, offset octeti            ; SI = inceput vector octeti

    pas2_loop:                       ; Bucla pentru PAS 2
        mov al, [si]                 ; AL = octet curent
        shr al, 2                    ; Mutam bits 2..5 spre jos (devin 0..3)
        and al, 0Fh                  ; Pastram doar 4 biti
        or  bl, al                   ; OR acumulat in BL
        inc si                       ; Urmatorul octet
    loop pas2_loop                   ; CX-- si repeta daca CX != 0

    and bl, 0Fh                      ; BL ramane doar pe 4 biti (0..3)

    xor ax, ax                       ; AX = 0 (vom face suma in AL)
    xor ch, ch                       ; CH = 0
    mov cl, nocteti                  ; CL = nr octeti
    mov si, offset octeti            ; SI = inceput vector

    pas3_loop:                       ; Bucla pentru PAS 3
        add al, [si]                 ; Suma octetilor in AL (overflow = mod 256)
        inc si                       ; Urmatorul
    loop pas3_loop                   ; Repetam pentru toti octetii

    mov ah, al                       ; AH = suma (bits 8..15 din C)
    shl bl, 4                        ; Mutam nibble-ul PAS 2 in bits 4..7
    or  bl, dl                       ; Lipim cu nibble-ul PAS 1 (bits 0..3)

    mov al, bl                       ; AL = byte inferior (bits 0..7) din C
    mov C, ax                        ; Salvam C (AX = [AH:AL])

    lea si, hex_tbl                  ; SI = tabel hexa
    lea di, bufC                     ; DI = buffer pentru afisare

    ; cifra 1: semi-octet superior din AH
    mov bl, ah                       ; BL = AH
    shr bl, 4                        ; BL = nibble superior
    and bl, 0Fh                      ; Masca 4 biti
    xor bh, bh                       ; BX = index curat
    mov dl, [si+bx]                  ; DL = caracterul hexa
    mov [di], dl                     ; Scriem in buffer
    inc di                           ; Avansam

    ; cifra 2: semi-octet inferior din AH
    mov bl, ah                       ; BL = AH
    and bl, 0Fh                      ; BL = nibble inferior
    xor bh, bh                       ; Curatam BH
    mov dl, [si+bx]                  ; Caracter hexa
    mov [di], dl                     ; Scriem
    inc di                           ; Avansam

    ; cifra 3: semi-octet superior din AL
    mov bl, al                       ; BL = AL
    shr bl, 4                        ; BL = nibble superior
    and bl, 0Fh                      ; Masca 4 biti
    xor bh, bh                       ; Curatam BH
    mov dl, [si+bx]                  ; Caracter hexa
    mov [di], dl                     ; Scriem
    inc di                           ; Avansam

    ; cifra 4: semi-octet inferior din AL
    mov bl, al                       ; BL = AL
    and bl, 0Fh                      ; BL = nibble inferior
    xor bh, bh                       ; Curatam BH
    mov dl, [si+bx]                  ; Caracter hexa
    mov [di], dl                     ; Scriem
    ; urmeaza deja '$' in bufC       ; Bufferul are deja terminator

    ; afisare mesaj
    mov ah, 09h                      ; Afisare sir $
    lea dx, msj_C                    ; DX = mesaj "Cuvantul C..."
    int 21h                          ; Apel DOS

    ; afisare valoare C (hex, ASCII)
    mov ah, 09h                      ; Afisare sir $
    lea dx, bufC                     ; DX = "XXXX$"
    int 21h                          ; Apel DOS

;============================================================
; MANIPULAREA SIRULUI DE OCTETI
;============================================================

    mov cl, nocteti                  ; CL = n
    dec cl                           ; CL = n-1 (treceri exterioare)

outer_loop:                          ; Bubble sort: bucla externa
    mov si, offset octeti            ; SI = inceput vector
    mov ch, cl                       ; CH = numar comparatii interne

inner_loop:                          ; Bubble sort: bucla interna
    mov al, [si]                     ; AL = element curent
    mov bl, [si+1]                   ; BL = urmatorul element
    cmp al, bl                       ; Comparam
    jae no_swap                      ; Daca AL >= BL, e deja descrescator

    ; altfel se face swap
    mov [si], bl                     ; Punem elementul mai mare inainte
    mov [si+1], al                   ; Mutam celalalt dupa

no_swap:                             ; Nu s-a facut swap sau s-a terminat swap
    inc si                           ; Avansam la urmatoarea pereche
    dec ch                           ; Scadem contorul intern
    jnz inner_loop                   ; Repetam daca mai avem comparatii

    dec cl                           ; Scadem trecerea externa
    jnz outer_loop                   ; Repetam daca mai sunt treceri
; s-a terminat sortarea              ; Vectorul este acum sortat descrescator

    mov max_bits, 0                  ; Resetam maximul de biti 1
    mov poz_max, 0                   ; Resetam pozitia

    lea si, octeti                   ; SI = inceput vector
    mov cl, nocteti                  ; CL = nr elemente
    xor ch, ch                       ; CX = nr elemente (CH=0)

    xor di, di                       ; DI = index curent (0,1,2,...)

find_loop:                           ; Cautam octetul cu cei mai multi biti 1 (>3)
    cmp cx, 0                        ; Mai avem elemente?
    je  find_done                    ; Daca nu, gata

    mov al, [si]                     ; AL = octet curent

    ; numaram bitii 1 in AL -> BL
    mov ah, al                       ; AH = copie (ca sa shiftam fara grija)
    xor bl, bl                       ; BL = contor biti 1
    mov bp, 8                        ; BP = 8 biti de verificat
count_bits:                          ; Bucla de numarare biti
    shl ah, 1                        ; Shift stanga: bitul 7 ajunge in CF
    jnc bit0                         ; Daca CF=0, bitul era 0
    inc bl                           ; Daca CF=1, incrementam contorul
bit0:                                ; Eticheta pentru cazul bit=0
    dec bp                           ; Un bit verificat
    jne count_bits                   ; Repetam pana la 8 biti

    ; BL = nr biti 1
    cmp bl, 3                        ; Conditia: strict > 3
    jbe not_candidate                ; Daca <=3, nu ne intereseaza

    mov al, max_bits                 ; AL = maximul curent
    cmp bl, al                       ; BL > max_bits ?
    jbe not_candidate                ; Daca nu e mai mare, nu actualizam

    ; update max + pozitie
    mov max_bits, bl                 ; Salvam noul maxim
    mov ax, di                       ; AX = index curent
    mov poz_max, al                  ; Salvam pozitia (byte)

not_candidate:                       ; Trecem la urmatorul element
    inc si                           ; SI -> urmator octet
    inc di                           ; index++
    dec cx                           ; un element procesat
    jmp find_loop                    ; continuam cautarea

find_done:                           ; Am terminat cautarea

    mov ah, 09h                      ; Afisare sir $
    lea dx, msj_poz                  ; Mesaj pentru pozitie
    int 21h                          ; Apel DOS

    lea si, hex_tbl                  ; SI = tabel hex
    lea di, bufC                     ; DI = buffer

    mov ah, poz_max                  ; AH = valoarea (pozitia) de afisat

    ; cifra 1: semi-octet superior din AH
    mov bl, ah                       ; BL = AH
    shr bl, 4                        ; BL = nibble superior
    and bl, 0Fh                      ; Masca 4 biti
    xor bh, bh                       ; BX curat
    mov dl, [si+bx]                  ; DL = caracter hex
    mov [di], dl                     ; Scriem in buffer
    inc di                           ; Avansam

    ; cifra 2: semi-octet inferior din AH
    mov bl, ah                       ; BL = AH
    and bl, 0Fh                      ; BL = nibble inferior
    xor bh, bh                       ; Curatam BH
    mov dl, [si+bx]                  ; DL = caracter hex
    mov [di], dl                     ; Scriem
    inc di                           ; Avansam

    mov byte ptr [di], '$'           ; Terminator pentru afisare AH=09h

    mov ah, 09h                      ; Afisare sir $
    lea dx, bufC                     ; Afisam pozitia in hex (2 cifre)
    int 21h                          ; Apel DOS

;============================================================
; ROTIRI SI SHIFTARI
;============================================================

    ; afisare mesaj al cerintei
    mov ah, 09h                      ; Afisare sir $
    lea dx, msj_rot                  ; Mesaj rotiri
    int 21h                          ; Apel DOS

    lea si, octeti                   ; SI = inceput vector
    mov cl, nocteti                  ; CL = nr octeti
    xor ch, ch                       ; CX = nr octeti

rot_loop:                            ; Bucla prin fiecare octet
    cmp cx, 0                        ; Mai avem elemente?
    jne rot_cont                     ; Daca da, continuam
    jmp rot_done                     ; Daca nu, iesim
rot_cont:                            ; Corpul buclei

    mov al, [si]                     ; AL = octet curent

    ; N = bit7 + bit6
    mov ah, al                       ; AH = copie
    shr ah, 6                        ; Mutam bit7..bit6 in bit1..bit0
    and ah, 03h                      ; Pastram doar 2 biti (00..11)
    ; aducem primii doi biti pe pozitiile 0 si 1
    ; AH devine = 0, 1, 2 sau 3 (facem o masca 000000xx)

    ; ROL fara CL (nu stricam CX)
    cmp ah, 0                        ; Daca N=0
    je  rot_ok                       ; Nu rotim
    cmp ah, 1                        ; Daca N=1
    je  rot1                         ; Rotim o data
    rol al, 1                        ; Pentru N=2 sau 3: rotim o data aici
rot1:
    rol al, 1                        ; Mai rotim o data (total 1 sau 2)
rot_ok:
    ; fac rotirea cu N pozitii fara CX deoarece este contorul buclei externe
    mov tmp_rot, al                  ; Salvam octetul rotit

    ; ===== BIN in bufC =====
    lea di, bufC                     ; DI = inceput buffer
    mov bl, tmp_rot                  ; BL = valoare pentru extragere biti
    mov bp, 8                        ; BP = 8 biti

bin_to_buf:                          ; Convertim in '0'/'1'
    shl bl, 1                        ; Bitul curent ajunge in CF
    jc  bit_is_1                     ; Daca CF=1 -> bit=1
    mov byte ptr [di], '0'           ; Scriem '0'
    jmp bit_done                     ; Sarim peste cazul '1'

bit_is_1:
    mov byte ptr [di], '1'           ; Scriem '1'

bit_done:
    inc di                           ; Urmatoarea pozitie in buffer
    dec bp                           ; Scadem numarul de biti ramasi
    jne bin_to_buf                   ; Repetam pana la 8 biti
    ; shiftez din BL => bitul ajunge in CF => fac 8 shiftari ca sa identific bitii si sa
    ; ii scriu pe rand in ascii in buffer

    mov byte ptr [di], '$'           ; Terminator pentru afisare

    mov ah, 09h                      ; Afisare sir $
    lea dx, bufC                     ; Afisam cei 8 biti
    int 21h                          ; Apel DOS
    ; afisam sirul din buffer

    mov ah, 02h                      ; Functie DOS: afisare caracter
    mov dl, ' '                      ; DL = spatiu
    int 21h                          ; Afisam spatiu
    ; spatiu

    ; ===== HEX in bufC =====
    push si                          ; Salvam SI (il folosim temporar)

    lea si, hex_tbl                  ; SI = tabel hex
    lea di, bufC                     ; DI = buffer

    mov ah, tmp_rot                  ; AH = valoarea de convertit (un byte)

    ; cifra 1: semi-octet superior
    mov bl, ah                       ; BL = valoare
    shr bl, 4                        ; BL = nibble superior
    and bl, 0Fh                      ; Masca 4 biti
    xor bh, bh                       ; BX curat
    mov dl, [si+bx]                  ; DL = caracter hex
    mov [di], dl                     ; Scriem
    inc di                           ; Avansam

    ; cifra 2: semi-octet inferior
    mov bl, ah                       ; BL = valoare
    and bl, 0Fh                      ; BL = nibble inferior
    xor bh, bh                       ; Curatam BH
    mov dl, [si+bx]                  ; DL = caracter hex
    mov [di], dl                     ; Scriem
    inc di                           ; Avansam

    mov byte ptr [di], '$'           ; Terminator $

    mov ah, 09h                      ; Afisare sir $
    lea dx, bufC                     ; Afisam cei 2 hex
    int 21h                          ; Apel DOS

    pop si                           ; Refacem SI (inapoi la vector)

    ; newline
    mov ah, 02h                      ; Afisare caracter
    mov dl, 13                       ; CR
    int 21h                          ; Afisam CR
    mov dl, 10                       ; LF
    int 21h                          ; Afisam LF

    inc si                           ; Trecem la urmatorul octet
    dec cx                           ; Un octet procesat
    jmp rot_loop                     ; Repetam

rot_done:                            ; Am terminat rotirile si afisarile

    mov ah, 08h                      ; Functie DOS: asteapta o tasta (fara ecou)
    int 21h                          ; Apel DOS

    mov ax, 4C00h                    ; Functie DOS: terminare program (cod 0)
    int 21h                          ; Iesire in DOS
code ENDS                            ; Sfarsit segment cod
END start                            ; Sfarsit program, entry point = start
