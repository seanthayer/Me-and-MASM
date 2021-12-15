TITLE Rivest Cipher 4 (RC4.asm)

; Reference:
; https://wikipedia.org/wiki/RC4
;

INCLUDE Irvine32.inc

KEY_LENGTH = 4
MESSAGE_LENGTH = 6

index_i EQU DWORD PTR [ebp - 4]
index_j EQU DWORD PTR [ebp - 8]
index_l EQU DWORD PTR [ebp - 12]


.data

    S           BYTE    256 DUP(0)
    key         BYTE    "Wiki"

    message     BYTE    "pedia", 0

    CIPHER_KEY  BYTE    MESSAGE_LENGTH DUP(0)
    CIPHER      BYTE    MESSAGE_LENGTH DUP(0)

    decipherMsg BYTE    MESSAGE_LENGTH DUP(0)

    ; ----- PROMPTS -----

    msgKeyLngth BYTE    "Calling KSA with key length of: ", 0
    msgKey      BYTE    "Corresponding to a key of: ", 0
    msgKSADone  BYTE    "KSA complete.", 0

    msgMsgLngth BYTE    "Calling PRGA with a message length of (including terminating char): ", 0
    msgMsg      BYTE    "Corresponding to a message of: ", 0
    msgPRGADone BYTE    "PRGA complete.", 0

    msgCpher    BYTE    "PRGA returned a cipher of: ", 0
    msgCpherK   BYTE    "With a cipher key of: ", 0

    msgDecpher  BYTE    "Calling DECIPHER with CIPHER and CIPHER_KEY.", 0
    msgDcphrDne BYTE    "DECIPHER complete.", 0
    msgDcphrMsg BYTE    "DECIPHER returned a message of: ", 0

.code
main PROC

    ; ----- KSA PROMPTS -----

    mov     edx, OFFSET msgKeyLngth
    call    WriteString
    mov     eax, KEY_LENGTH
    call    WriteDec
    call    Crlf

    mov     edx, OFFSET msgKey
    call    WriteString
    mov     eax, 0
    mov     ecx, KEY_LENGTH
    mov     esi, OFFSET key

    Key_Print:
        mov     al, [esi]
        call    WriteHex
        mov     al, " "
        call    WriteChar

        inc     esi

    loop Key_Print

    ; --------------------


    push    KEY_LENGTH  ; [LENGTH]
    push    OFFSET key  ; [KEY]
    push    OFFSET S    ; [S]
    call    KSA


    ; ----- PRGA PROMPTS -----

    call    Crlf
    call    Crlf
    mov     edx, OFFSET msgKSADone
    call    WriteString
    call    Crlf
    call    Crlf

    mov     edx, OFFSET msgMsgLngth
    call    WriteString
    mov     eax, MESSAGE_LENGTH
    call    WriteDec
    call    Crlf

    mov     edx, OFFSET msgMsg
    call    WriteString
    mov     eax, 0
    mov     esi, OFFSET message

    MessageHex_Print:
        mov     al, [esi]
        cmp     al, 0
        je      MessageHex_PrintDone

        call    WriteHex
        mov     al, " "
        call    WriteChar

        inc     esi
        
    jmp     MessageHex_Print

    MessageHex_PrintDone:

    mov     eax, 0
    mov     al, "("
    call    WriteChar
    mov     edx, OFFSET message
    call    WriteString
    mov     al, ")"
    call    WriteChar

    ; --------------------


    push    OFFSET S            ; [S]
    push    OFFSET message      ; [MESSAGE]
    push    OFFSET CIPHER_KEY   ; [CIPHER_KEY]
    push    OFFSET CIPHER       ; [CIPHER]
    call    PRGA


    ; ----- CIPHER PROMPTS -----

    call    Crlf
    call    Crlf
    mov     edx, OFFSET msgPRGADone
    call    WriteString
    call    Crlf
    call    Crlf

    mov     edx, OFFSET msgCpher
    call    WriteString
    mov     eax, 0
    mov     esi, OFFSET CIPHER

    Cipher_Print:
        mov     al, [esi]
        cmp     al, 0
        je      Cipher_PrintDone

        call    WriteHex
        mov     al, " "
        call    WriteChar

        inc     esi
        
    jmp     Cipher_Print

    Cipher_PrintDone:

    call    Crlf
    mov     edx, OFFSET msgCpherK
    call    WriteString
    mov     eax, 0
    mov     esi, OFFSET CIPHER_KEY

    CipherKey_Print:
        mov     al, [esi]
        cmp     al, 0
        je      CipherKey_PrintDone

        call    WriteHex
        mov     al, " "
        call    WriteChar

        inc     esi
        
    jmp     CipherKey_Print

    CipherKey_PrintDone:


    call    Crlf
    call    Crlf
    mov     edx, OFFSET msgDecpher
    call    WriteString

    ; --------------------


    push    OFFSET CIPHER_KEY   ; [CIPHER_KEY]
    push    OFFSET CIPHER       ; [CIPHER]
    push    OFFSET decipherMsg  ; [MESSAGE]
    call    DECIPHER


    ; ----- DECIPHER PROMPTS -----

    call    Crlf
    call    Crlf
    mov     edx, OFFSET msgDcphrDne
    call    WriteString

    call    Crlf
    call    Crlf
    mov     edx, OFFSET msgDcphrMsg
    call    WriteString
    mov     eax, 0
    mov     esi, OFFSET decipherMsg

    DecipherHex_Print:
        mov     al, [esi]
        cmp     al, 0
        je      DecipherHex_PrintDone

        call    WriteHex
        mov     al, " "
        call    WriteChar

        inc     esi
        
    jmp     DecipherHex_Print

    DecipherHex_PrintDone:

    mov     eax, 0
    mov     al, "("
    call    WriteChar
    mov     edx, OFFSET decipherMsg
    call    WriteString
    mov     al, ")"
    call    WriteChar
    call    Crlf

    ; --------------------


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
;               j := (j + S[i] + key[i mod KEY_LENGTH]) mod 256
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

    S_Init:

        ; for i from 0 to 255

        mov     [esi], al ; S[i] := i

        inc     esi
        inc     al

    loop    S_Init


    mov     index_i, 0

    mov     ebx, 0          ; EBX will be index 'j', thus, j := 0
    mov     ecx, 256
    mov     esi, [ebp + 8]  ; [S]
    mov     edi, [ebp + 12] ; [KEY]

    S_Init2:

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

        mov     ebx, edx    ; j := (j + S[i] + key[i mod KEY_LENGTH]) mod 256

        mov     eax, index_i

        add     esi, ebx    ;
        push    esi         ; - &j
        sub     esi, ebx    ;

        add     esi, eax    ;
        push    esi         ; - &i
        sub     esi, eax    ;

        call    exchangeElements ; swap S[i] <-> S[j]

        inc     index_i

    loop    S_Init2


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
;            l := 0
;            while Message[l]:
;                i := (i + 1) mod 256
;                j := (j + S[i]) mod 256
;
;                swap values of S[i] and S[j]
;
;                K := S[(S[i] + S[j]) mod 256]
;
;                output K -> CipherKey[l]
;
;                Cipher[l] := Message[l] XOR CipherKey[l]
;
;                l := l + 1
;            endwhile
;           ------------------------------------------
;
; RECEIVES: PARAM_4: 32-bit OFFSET BYTE  [S]
;           PARAM_3: 32-bit OFFSET BYTE  [MESSAGE]
;           PARAM_2: 32-bit OFFSET BYTE  [CIPHER_KEY]
;           PARAM_1: 32-bit OFFSET BYTE  [CIPHER]
; 
; RETURNS:  PARAM_2: 32-bit OFFSET BYTE  [CIPHER_KEY]
;           PARAM_1: 32-bit OFFSET BYTE  [CIPHER]
;
; PRE-:     Parameters are byte arrays. [S] has been initialized using the Key-scheduling algorithm.
;
; POST-:    [CIPHER_KEY] contains the [S] values used for the XOR at 'i' position.
;           [CIPHER] contains the encrypted values.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
PRGA PROC
    enter   12, 0

    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
    push    esi


    mov     eax, 0
    mov     ecx, [ebp + 8]  ; [CIPHER]
    mov     edx, 0
    mov     edi, [ebp + 20] ; [S]
    mov     esi, [ebp + 16] ; [MESSAGE]

    mov     index_i, 0      ; i := 0
    mov     index_j, 0      ; j := 0
    mov     index_l, 0      ; l := 0

    PRGA_Loop:

        ; while Message[l]

        mov     dl, [esi]
        cmp     dl, 0
        je      PRGA_Done

        inc     index_i

        push    index_i
        push    256
        call    quickModulo

        mov     index_i, edx ; i := (i + 1) mod 256

        mov     ebx, 0
        mov     bl, [edi + edx]
        add     eax, ebx

        push    eax
        push    256
        call    quickModulo

        mov     index_j, edx ; j := (j + S[i]) mod 256

        lea     ebx, [edi + edx] ; - &j
        push    ebx              ;

        mov     edx, index_i     ;
        lea     ebx, [edi + edx] ; - &i
        push    ebx              ;

        call    exchangeElements ; swap S[i] <-> S[j]

        mov     eax, 0
        mov     ebx, 0

        mov     bl, [edi + edx] ; S[i]

        mov     edx, index_j

        mov     al, [edi + edx] ; S[j]

        add     eax, ebx ; (S[i] + S[j])

        push    eax
        push    256
        call    quickModulo

        mov     eax, 0
        mov     al, [edi + edx] ; K := S[(S[i] + S[j]) mod 256]

        mov     ebx, [ebp + 12] ; [CIPHER_KEY]
        add     ebx, index_l

        mov     [ebx], al ; output K -> CipherKey[l]

        mov     dl, [esi]
        mov     [ecx], dl

        xor     [ecx], al ; Cipher[l] := Message[l] XOR CipherKey[l]

        inc     index_l ; l := l + 1

        inc     ecx     ; Incrementation of 'l' is implicit for 'Cipher' and 'Message'
        inc     esi     ; Yes, it's sloppy

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
    ret     16
PRGA ENDP

; ---------------------------------------------------------------------
; NAME:     DECIPHER
;
; DESC:     Reverses the bitwise XOR operation for a [CIPHER] with its given [CIPHER_KEY].
;           Returns the cipher's original message.
;
; RECEIVES: PARAM_3: 32-bit OFFSET BYTE  [CIPHER_KEY]
;           PARAM_2: 32-bit OFFSET BYTE  [CIPHER]
;           PARAM_1: 32-bit OFFSET BYTE  [MESSAGE]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [MESSAGE]
;
; PRE-:     [CIPHER_KEY] contains the key values used to XOR each character in [CIPHER] at each 'i' position.
;           [CIPHER] contains the values resulting from a bitwise XOR using [CIPHER_KEY] and the original message.
;
; POST-:    [MESSAGE] contains the deciphered message.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
DECIPHER PROC
    enter   0, 0

    push    eax
    push    ebx
    push    ecx
    push    edi
    push    esi

    mov     eax, 0
    mov     ebx, 0
    mov     ecx, [ebp + 8]  ; [MESSAGE]
    mov     edi, [ebp + 12] ; [CIPHER]
    mov     esi, [ebp + 16] ; [CIPHER_KEY]

    Decipher_Loop:
        mov     bl, [edi]
        cmp     bl, 0
        je      Decipher_Done

        mov     al, [esi]
        mov     [ecx], al

        xor     [ecx], bl

        inc     ecx
        inc     edi
        inc     esi

    jmp     Decipher_Loop

    Decipher_Done:

    pop     esi
    pop     edi
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     12
DECIPHER ENDP

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
