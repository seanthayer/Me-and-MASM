TITLE Rivest Cipher 4 (RC4.asm)

; Reference:
; https://wikipedia.org/wiki/RC4
;

INCLUDE Irvine32.inc


index_i EQU DWORD PTR [ebp - 4]
index_j EQU DWORD PTR [ebp - 8]
index_k EQU DWORD PTR [ebp - 12]

; TO DO: - fix decryption
;        - refactor PRGA

.data

    ; 'S' for stream, or byte stream in this case.
    S           BYTE    256 DUP(0)

    key         BYTE    "Wiki"
    keyLength   DWORD   4

    message     BYTE    "pedia", 0

    CIPHER      BYTE    6 DUP(0)

.code
main PROC

    push    keyLength   ; [LENGTH]
    push    OFFSET key  ; [KEY]
    push    OFFSET S    ; [S]
    call    KSA

    push    OFFSET S        ; [S]
    push    OFFSET message  ; [MESSAGE]
    push    OFFSET CIPHER   ; [CIPHER]
    call    PRGA

;    mov     eax, 0
;    mov     ecx, 256
;    mov     esi, OFFSET S
;
;    print2:
;        mov     al, [esi]
;
;        inc     esi
;
;    loop    print2

    mov     eax, 0
    mov     esi, OFFSET CIPHER

    print:
        mov     al, [esi]
        cmp     al, 0
        je      printDone

        call    WriteHex
        call    Crlf

        inc     esi
        
    jmp     print

    printDone:

	exit
main ENDP

; ---------------------------------------------------------------------
; NAME:     KSA (Key-scheduling algorithm)
;
; DESC:     Completes the following pseudo-code:
;           ------------------------------------------
;           for i from 0 to 255
;               S[i] := i
;           endfor
;
;           j := 0
;           for i from 0 to 255
;               j := (j + S[i] + key[i mod keylength]) mod 256
;               swap values of S[i] and S[j]
;           endfor
;           ------------------------------------------
;
;           This sets the value of each index in 'S' to its position within 'S'.  i.e., S[0] = 0, S[1] = 1, ... S[n] = n
;           Then, values are pseudo-randomly swapped within 'S', using bytes from [KEY] to seed.
;
; RECEIVES: PARAM_3: 32-bit . . .  DWORD [LENGTH]
;           PARAM_2: 32-bit OFFSET BYTE  [KEY]
;           PARAM_1: 32-bit OFFSET BYTE  [S]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE [S]
;
; PRE-:     [S] is a byte array with a length of 256. [KEY] is a byte array with [LENGTH] > 0.
;
; POST-:    [S] is initialized according to the KSA.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
KSA PROC
    enter   4, 0

    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi

    mov     eax, 0
    mov     ecx, 256
    mov     esi, [ebp + 8] ; [S]

    initS:

        ; for i from 0 to 255

        mov     [esi], al ; S[i] := i

        inc     esi
        inc     al

    loop    initS

    mov     index_i, 0

    mov     eax, 0
    mov     ebx, 0          ; EBX will be index 'j'
    mov     ecx, 256
    mov     esi, [ebp + 8]  ; [S]
    mov     edi, [ebp + 12] ; [KEY]

    initS2:

        ; for i from 0 to 255

        push    index_i
        push    [ebp + 16]  ; [LENGTH]
        call    quickModulo
        ; EDX holds modulo

        mov     al, [edi + edx] ; Get byte value from modulo position in [KEY]

        add     ebx, eax

        mov     edx, index_i
        mov     al, [esi + edx] ; S[i]

        add     ebx, eax

        push    ebx
        push    256
        call    quickModulo

        mov     ebx, edx    ; j := (j + S[i] + key[i mod keylength]) mod 256

        mov     eax, index_i

        add     esi, ebx    ;
        push    esi         ; - &j
        sub     esi, ebx    ;

        add     esi, eax    ;
        push    esi         ; - &i
        sub     esi, eax    ;

        call    exchangeElements ; swap S[i] <-> S[j]

        inc     index_i

    loop    initS2

    pop     esi
    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     12
KSA ENDP

; ---------------------------------------------------------------------
; NAME:     PRGA (Pseudo-random generation algorithm)
;
; DESC:     Completes the following pseudo-code:
;           ------------------------------------------
;            i := 0
;            j := 0
;            while GeneratingOutput:
;                i := (i + 1) mod 256
;                j := (j + S[i]) mod 256
;
;                swap values of S[i] and S[j]
;
;                K := S[(S[i] + S[j]) mod 256]
;
;                output K
;            endwhile
;           ------------------------------------------
;
; RECEIVES: PARAM_3: 32-bit OFFSET BYTE  [S]
;           PARAM_2: 32-bit OFFSET BYTE  [MESSAGE]
;           PARAM_1: 32-bit OFFSET BYTE  [CIPHER]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [CIPHER]
;
; PRE-:     Parameters are byte arrays. [S] has been
;           initialized using the Key-scheduling algorithm.
;
; POST-:    [CIPHER] contains the encrypted / decrypted values.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
PRGA PROC
    enter   8, 0

    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi

    ; A bit messy in here

    mov     eax, 0
    mov     ebx, 0
    mov     ecx, [ebp + 8]  ; [CIPHER]
    mov     edx, 0
    mov     edi, [ebp + 16] ; [S]
    mov     esi, [ebp + 12] ; [MESSAGE]
    mov     index_i, 0
    mov     index_j, 0

    PRGA_Loop:
        mov     dl, [esi]
        cmp     dl, 0
        je      PRGA_Done

        inc     index_i

        push    index_i
        push    256
        call    quickModulo

        mov     index_i, edx

        mov     ebx, 0
        mov     bl, [edi + edx]
        add     eax, ebx

        push    eax
        push    256
        call    quickModulo

        mov     eax, edx
        mov     index_j, eax

        lea     ebx, [edi + edx]
        push    ebx

        mov     edx, index_i
        lea     ebx, [edi + edx]
        push    ebx

        call    exchangeElements

        mov     eax, 0
        mov     ebx, 0

        mov     bl, [edi + edx] ; S[i]

        mov     edx, index_j

        mov     al, [edi + edx] ; S[j]

        add     eax, ebx

        push    eax
        push    256
        call    quickModulo

        mov     eax, 0
        mov     al, [edi + edx]

        mov     dl, [esi]
        mov     [ecx], dl

        ; BUG: Correctly encrypts, incorrectly decrypts
        xor     [ecx], al

        inc     esi
        inc     ecx

        mov     eax, index_j

    jmp     PRGA_Loop

    PRGA_Done:

    pop     esi
    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     12
PRGA ENDP

; ---------------------------------------------------------------------
; NAME:     quickModulo
;
; DESC:     Calculates the modulo of two unsigned 32-bit values and stores the result
;           in the 32-bit EDX register.
;
; RECEIVES: PARAM_3: REGISTER      EDX   [MODULO]
;           PARAM_2: 32-bit . . .  DWORD [DIVIDEND]
;           PARAM_1: 32-bit . . .  DWORD [DIVISOR]
; 
; RETURNS:  PARAM_3: REGISTER      EDX   [MODULO]
;
; PRE-:     The divisor is not 0, and the divisor & dividend are unsigned 32-bit parameters
;           passed by value. The 32-bit EDX register will be overwritten with the resulting modulo.
;
; POST-:    EDX contains [MODULO] of [DIVIDEND] & [DIVISOR]
;
; CHANGES:  EAX (restored);     EBX (restored);     EDX;
; ---------------------------------------------------------------------
quickModulo PROC
    enter   0, 0
    
    push    eax
    push    ebx

    mov     eax, [ebp + 12] ; [DIVIDEND]
    mov     ebx, [ebp + 8]  ; [DIVISOR]

    cmp     ebx, 0
    je      DivByZero

    cdq

    div     ebx

    DivByZero:

    pop     ebx
    pop     eax

    leave
    ret     8
quickModulo ENDP

; ---------------------------------------------------------------------
; NAME:     exchangeElements
;
; DESC:     Swaps two elements in an array.
;
; RECEIVES: PARAM_2: 32-bit Memory address of 'j'. (&j)
;           PARAM_1: 32-bit Memory address of 'i'. (&i)
; 
; RETURNS:  None.
;
; PRE-:     The elements are of 8-bit size.
;
; POST-:    The elements are swapped.
;
; CHANGES:  EAX (restored);      EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
exchangeElements PROC 
    enter   0, 0

    push    eax
    push    edi
    push    esi

    mov     esi, [ebp + 12]
    mov     edi, [ebp + 8]

    mov     al, [esi]
    xchg    al, [edi]
    mov     [esi], al

    pop     esi
    pop     edi
    pop     eax

    leave
    ret     8       ; STDCALL
exchangeElements ENDP

END main
