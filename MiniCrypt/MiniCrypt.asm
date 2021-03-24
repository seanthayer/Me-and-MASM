TITLE MiniCrypt  (MiniCrypt.asm)

INCLUDE Irvine32.inc


index_i EQU DWORD PTR [ebp - 4]
index_j EQU DWORD PTR [ebp - 8]
index_k EQU DWORD PTR [ebp - 12]


.data

    ; 'S' for stream, or byte stream in this case.
    S           BYTE    256 DUP(0)

    key         BYTE    "Secret"
    keyLength   DWORD   6

    message     BYTE    "the contents of this message will be a mystery.", 0

.code
main PROC

    push    keyLength   ; [LENGTH]
    push    OFFSET key  ; [KEY]
    push    OFFSET S    ; [S]
    call    KSA

    push    256         ; [LENGTH]
    push    OFFSET S    ; [LIST]
    call    sortList

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
; NAME:     sortList
;
; DESC:     Sorts a given byte array in ascending order using a selection sort.
;
; RECEIVES: PARAM_2: 32-bit . . .  DWORD [LENGTH]
;           PARAM_1: 32-bit OFFSET BYTE  [LIST]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [LIST]
;
; PRE-:     [LIST] is a byte array.
;
; POST-:    [LIST] is sorted in ascending order.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     ESI (restored);
; ---------------------------------------------------------------------
sortList PROC 
    enter   12, 0

    push    eax
    push    ebx
    push    ecx
    push    esi

    mov     eax, 0
    mov     ebx, 0
    mov     ecx, [ebp + 12] ; [LENGTH]
    mov     esi, [ebp + 8]  ; [LIST]

    mov     index_i, 0 ; 'i' represents the lower bound of the interval [ i, n ], where 'n' is '[LENGTH] - 1'.
    mov     index_j, 0 ; 'j' iterates through the array, keeping track of the position of current element.
    mov     index_k, 0 ; 'k' keeps track of the current selected minimum element.

    ; A selection sort works by selecting the minimum element within a shrinking interval of the full set.
    ; The pseudo-code for the following implementation is as follows (although 'n' is not explicitly defined):
    ; -----------------------------------------
    ;           S := set of variable length
    ;           n := [LENGTH] - 1
    ;           i, j, k := 0
    ;
    ;           for i from 0 to n
    ;               k := i
    ;               
    ;               for j from i to n
    ;
    ;                   if S[j] < S[k]
    ;                       k := j
    ;                   
    ;               endfor
    ;
    ;               if k != i
    ;                   swap S[i] <-> S[k]
    ;
    ;           endfor
    ; -----------------------------------------
    ;
    ; That is to say, iterate through the set on the shrinking interval of [ i, n ] with minimum element position starting at 'k := i'.
    ; Move through set 'S' via 'j', and if a smaller element is found at 'j' position then select it with 'k := j'.
    ; Finally, if an element besides S[i] was selected, swap S[i] & S[k] and shrink the interval until reaching max index 'n'.

    sortLoop:
        add     esi, index_i
        mov     al, [esi]       ; S[i]

        mov     ebx, index_i
        mov     index_k, ebx    ; k := i
        mov     index_j, ebx    ; j := i (for loop starting val)

        subsort:

            ; for j from i to n

            inc     index_j
            cmp     index_j, ecx ; (j >= [LENGTH]), same as saying, (j on the interval [ i, n ])
            jge     swap

            inc     esi
            mov     bl, [esi]

                                    ; Not quite the same as the pseudo-code but the same in essence. This just words it differently:
                                    ; -----------------------------------------
                                    ; where 'ax' is selected minimum value S[k] and 'bx' is value S[j]
                                    ;
                                    ; for . . .
            cmp     ax, bx      ;-- ;
            jle     subsort     ;-- ;     if S[k] <= S[j]
                                    ;         continue
                                    ;     else
                                    ;         k := j
                                    ;
                                    ; endfor
                                    ; -----------------------------------------

            ; else

            mov     al, bl ; New selected minimum value

            mov     ebx, index_j
            mov     index_k, ebx ; k := j

            jmp     subsort

            swap:
                mov     esi, [ebp + 8] ; Reset array position
                mov     ebx, index_i
                cmp     index_k, ebx   ; Another slight difference from the pseudo-code
                je      noSort

                ; if k != i

                lea     ebx, [esi + ebx]
                push    ebx

                mov     ebx, index_k
                lea     ebx, [esi + ebx]
                push    ebx

                call    exchangeElements ; swap S[i] <-> S[k]

            noSort:
                ; --------------

        inc     index_i
        cmp     index_i, 256
        jge     sortFinish

    jmp     sortLoop

    sortFinish:
        ; --------------

    pop     esi
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     8
sortList ENDP

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
