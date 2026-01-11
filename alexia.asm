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

