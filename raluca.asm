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

