TITLE MiniCrypt  (MiniCrypt.asm)

INCLUDE Irvine32.inc

index_k EQU DWORD PTR [ebp - 4]
index_j EQU DWORD PTR [ebp - 8]
index_i EQU DWORD PTR [ebp - 12]

.data

    KSA         BYTE    256 DUP(0)

    key         BYTE    "Secret"
    keyLength   DWORD   6

    message     BYTE    "the contents of this message will be a mystery.", 0

.code
main PROC

    push    keyLength
    push    OFFSET key
    push    OFFSET KSA
    call    initializeKSA

    mov     eax, 0
    mov     ecx, 256
    mov     esi, OFFSET KSA
    printLoop:
        mov     al, [esi]

        call    WriteDec
        call    Crlf

        inc     esi

    loop    printLoop

	exit
main ENDP

; ---------------------------------------------------------------------
; NAME:     initializeKSA
;
; DESC:     Sets each element in the 256-byte stream as such: for 'i' from 0 to 255, S[i] := i
;
; RECEIVES: PARAM_3: 32-bit . . .  DWORD [LENGTH]
;           PARAM_2: 32-bit OFFSET BYTE  [KEY]
;           PARAM_1: 32-bit OFFSET BYTE  [KSA]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE [KSA_INITIALIZED]
;
; PRE-:     [KSA] is a byte array with a length of 256.
;
; POST-:    [KSA] is initialized as such: for 'i' from 0 to 255, S[i] := i
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
initializeKSA PROC
    enter   8, 0

    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi

    mov     eax, 0
    mov     ecx, 256
    mov     esi, [ebp + 8] ; [KSA]

    initS:
        mov     [esi], al

        inc     esi
        inc     al

    loop    initS

    mov     index_j, 0
    mov     index_i, 0

    mov     eax, 0
    ;mov     ebx, [ebp + 16] ; [LENGTH]
    mov     ecx, 256
    mov     esi, [ebp + 8]  ; [KSA]
    mov     edi, [ebp + 12] ; [KEY]

    initSJ:
        mov     index_i, 8

        push    index_i
        push    [ebp + 16]
        call    quickModulo

        ; EDX holds modulo

        mov     al, [edi + edx]

        add     ebx, index_i

        add     index_j, eax
        
        inc     esi
        inc     eax

    loop    initSJ

    pop     esi
    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     4
initializeKSA ENDP

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
; CHANGES:  EAX (restored);     EBX (restored);     EDI (restored);
; ---------------------------------------------------------------------
quickModulo PROC
    enter   0, 0
    
    push    eax
    push    ebx
    push    edi

    mov     eax, [ebp + 12] ; [DIVIDEND]
    mov     ebx, [ebp + 8]  ; [DIVISOR]
    mov     edi, [ebp + 16] ; [MODULO]

    cmp     ebx, 0
    jle     DivByZero

    cmp     eax, 0
    jl      SignedDiv

    cdq

    div     ebx

    DivByZero:
    SignedDiv:

    pop     edi
    pop     ebx
    pop     eax

    leave
    ret
quickModulo ENDP

END main
