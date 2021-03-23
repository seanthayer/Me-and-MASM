TITLE MiniCrypt  (MiniCrypt.asm)

INCLUDE Irvine32.inc

index_i EQU DWORD PTR [ebp - 4]

.data

    S           BYTE    256 DUP(0)

    key         BYTE    "Secret"
    keyLength   DWORD   6

    message     BYTE    "the contents of this message will be a mystery.", 0

.code
main PROC

    push    keyLength
    push    OFFSET key
    push    OFFSET S
    call    KSA

    mov     eax, 0
    mov     ecx, 256
    mov     esi, OFFSET S
    printLoop:
        mov     al, [esi]

        call    WriteDec
        call    Crlf

        inc     esi

    loop    printLoop

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
;           In plain English: Initialize each value in array 'S' to its corresponding index position within 'S'. i.e., S[0] = 0, S[1] = 1, ... S[n] = n
;                             Then, pseudo-randomly swap values within 'S', using bytes from [KEY].
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
        mov     [esi], al

        inc     esi
        inc     al

    loop    initS

    mov     index_i, 0

    mov     eax, 0
    mov     ebx, 0          ; EBX will be index 'j'
    mov     ecx, 256
    mov     esi, [ebp + 8]  ; [S]
    mov     edi, [ebp + 12] ; [KEY]

    initSJ:
        push    index_i
        push    [ebp + 16]  ; [LENGTH]
        call    quickModulo
        ; EDX holds modulo

        mov     al, [edi + edx]

        add     ebx, index_i
        add     ebx, eax

        push    ebx
        push    256
        call    quickModulo

        mov     ebx, edx

        mov     eax, index_i

        add     esi, ebx    ;
        push    esi         ; - &j
        sub     esi, ebx    ;

        add     esi, eax    ;
        push    esi         ; - &i
        sub     esi, eax    ;

        call    exchangeElements

        inc     index_i

    loop    initSJ

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
; NAME:     Encrypt
;
; DESC:     
;
; RECEIVES: 
; 
; RETURNS:  
;
; PRE-:     
;
; POST-:    
;
; CHANGES:  
; ---------------------------------------------------------------------
Encrypt PROC
    push    ebp
    mov     ebp, esp

    pop     ebp

    ret
Encrypt ENDP

; ---------------------------------------------------------------------
; NAME:     Decrypt
;
; DESC:     
;
; RECEIVES: 
; 
; RETURNS:  
;
; PRE-:     
;
; POST-:    
;
; CHANGES:  
; ---------------------------------------------------------------------
Decrypt PROC
    push    ebp
    mov     ebp, esp

    pop     ebp

    ret
Decrypt ENDP

; ---------------------------------------------------------------------
; NAME:     quickModulo
;
; DESC:     Calculates the modulo of two unsigned 32-bit values and stores the result
;           in the 32-bit EDX register.
;
; RECEIVES: PARAM_3: 32-bit REG.   EDX   [MODULO]
;           PARAM_2: 32-bit . . .  DWORD [DIVIDEND]
;           PARAM_1: 32-bit . . .  DWORD [DIVISOR]
; 
; RETURNS:  PARAM_3: 32-bit REG.   EDX   [MODULO]
;
; PRE-:     The divisor is not 0, and the divisor & dividend are 32-bit parameters
;           passed by value, and not signed. The 32-bit EDX register has no important data.
;
; POST-:    EDX, [MODULO] contains the resulting modulo of [DIVIDEND] & [DIVISOR]
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
