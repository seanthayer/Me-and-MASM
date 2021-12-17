TITLE Selection Sort (SelectionSort.asm)

INCLUDE Irvine32.inc


index_i EQU DWORD PTR [ebp - 4]
index_j EQU DWORD PTR [ebp - 8]
index_k EQU DWORD PTR [ebp - 12]

N = 15000

LO = 1
HI = 255


.data

    S           BYTE    N DUP(0)
    S_Length    DWORD   N

    break       BYTE    "-----------------------------------------", 0


.code
main PROC

    call    Randomize

    push    S_Length    ; [LENGTH]
    push    OFFSET S    ; [ARRAY]
    call    fillArray

    mov     eax, 0
    mov     ecx, S_Length
    mov     esi, OFFSET S

    printLoop:
        mov     al, [esi]

        call    WriteDec

        mov     al, 9
        call    WriteChar

        push    ecx
        push    15
        call    quickModulo

        cmp     edx, 1
        jne     no_break
        call    Crlf
        no_break:

        inc     esi

    loop    printLoop

    call    Crlf

    push    S_Length    ; [LENGTH]
    push    OFFSET S    ; [LIST]
    call    sortList

    mov     edx, OFFSET break
    call    Crlf
    call    WriteString
    call    Crlf
    call    Crlf

    mov     eax, 0
    mov     ecx, S_Length
    mov     esi, OFFSET S

    printLoop2:
        mov     al, [esi]

        call    WriteDec

        mov     al, 9
        call    WriteChar

        push    ecx
        push    15
        call    quickModulo

        cmp     edx, 1
        jne     no_break2
        call    Crlf
        no_break2:

        inc     esi

    loop    printLoop2
    
    exit
main ENDP

; ---------------------------------------------------------------------
; NAME:     fillArray
;
; DESC:     Fills a byte array with random integers in the interval [ LO, HI ], using Irvine library's
;           RandomRange procedure.
;
; RECEIVES: PARAM_2: 32-bit . . .  DWORD [LENGTH]
;           PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
;
; PRE-:     The array is correctly initialized and [LENGTH] > 0
;
; POST-:    The array is filled with random integers ranging from the defined constants: [ LO, HI ]
;
; CHANGES:  EAX (restored);     ECX (restored);     ESI (restored);
; ---------------------------------------------------------------------
fillArray PROC 
    enter   0, 0

    push    eax
    push    ecx
    push    esi

    mov     ecx, [ebp + 12]  ; [LENGTH]
    mov     esi, [ebp + 8]   ; [ARRAY]

    fill:
        mov     eax, HI
        inc     eax
        sub     eax, LO
        call    RandomRange

        add     eax, LO

        mov     [esi], al
        inc     esi

    loop    fill

    pop     esi
    pop     ecx
    pop     eax

    leave
    ret     8       ; STDCALL
fillArray ENDP

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
    mov     index_j, 0 ; 'j' iterates through the array, keeping track of the position of the current element.
    mov     index_k, 0 ; 'k' keeps track of the current selected minimum element.

    ; A selection sort works by selecting the minimum element within a shrinking sub-set of the main set, and moving that element to the beginning of the sub-set.
    ; The pseudo-code for the following implementation is as follows (although 'n' is not explicitly defined):
    ; -----------------------------------------
    ;           S := A set with 'length = [LENGTH]'
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
    ; That is to say, iterate through 'S' on the interval [ 0, n ] using 'i', with each minimum element position starting at 'i'. 'k := i'.
    ; Then, iterate through 'S' on the sub-interval [ i, n ] using 'j', and if an element at S[j] is smaller than the current minimum element S[k], select it. 'k := j'.
    ; Finally, if an element smaller than S[i] was found, swap it with S[k] and continue.

    sortLoop:
    
        ; for i from 0 to n
    
        add     esi, index_i
        mov     al, [esi]       ; S[i]

        mov     ebx, index_i
        mov     index_k, ebx    ; k := i
        mov     index_j, ebx    ; j := i

        subsort:

            ; for j from i to n

            inc     index_j
            cmp     index_j, ecx ; (j >= [LENGTH]), same as saying, (j on the interval [ i, n ])
            jge     swap

            inc     esi
            mov     ebx, 0
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
        cmp     index_i, ecx ; (i >= [LENGTH]), so 'i' up to 'n'.
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
