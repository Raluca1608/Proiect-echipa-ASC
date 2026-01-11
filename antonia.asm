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
