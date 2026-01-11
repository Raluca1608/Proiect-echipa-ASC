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

