TITLE Merge Sort (MergeSort.asm)

INCLUDE Irvine32.inc

index_p EQU DWORD PTR [ebp - 4]
index_q EQU DWORD PTR [ebp - 8]
index_r EQU DWORD PTR [ebp - 12]

n_1     EQU DWORD PTR [ebp - 4]
n_2     EQU DWORD PTR [ebp - 8]
A_L     EQU DWORD PTR [ebp - 12]
A_R     EQU DWORD PTR [ebp - 16]
index_k EQU DWORD PTR [ebp - 20]

N = 5000
SORT_TIMES = 1

LO = 1
HI = 255

INF = -1

; TO-DO:    - Fix bug:  as 'N' approaches large values, elements at the end
;                       of 'S' are overwritten and mis-sorted with higher frequency.
;                       Bad memory addressing?

.data

    hHeap       HANDLE  ?

    S           BYTE    N DUP(0)
    S_Length    DWORD   N

    break       BYTE    "-----------------------------------------", 0
    
    sortTimes   WORD    SORT_TIMES


.code
main PROC

    INVOKE  GetProcessHeap
    cmp     eax, NULL
    je      quit

    mov     hHeap, eax

    call    Randomize

    push    S_Length    ; [LENGTH]
    push    OFFSET S    ; [ARRAY]
    call    fillArray

    mov     eax, 0
    mov     ecx, S_Length
    mov     esi, OFFSET S

    print:
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

    loop    print

    call    Crlf

    multiSort:

    cmp     sortTimes, 0
    jle     quit

    mov     eax, S_Length
    dec     eax

    push    eax         ; [INDEX_R]
    push    0           ; [INDEX_P]
    push    OFFSET S    ; [ARRAY]
    call    mergeSort

    mov     edx, OFFSET break
    call    Crlf
    call    WriteString
    call    Crlf
    call    Crlf

    mov     eax, 0
    mov     ecx, S_Length
    mov     esi, OFFSET S

    printSorted:
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
        inc     ebx

    loop    printSorted
    
    dec     sortTimes
    jmp     multiSort

    quit:


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
; NAME:     mergeSort
;
; DESC:     Main sorting function. Recurses to divide [ARRAY] into single unit sub-arrays, and
;           calls 'merge' to handle the sorting of growing sub-arrays up to [ARRAY].
;           Completes the following pseudo-code
;           ------------------------------------------
;           Where 'A' is an array, and has indices 'p' <= 'q' < 'r'
;
;           if p < r
;               q = floor( (p + r) / 2 )
;               mergeSort(A, p, q)
;               mergeSort(A, q + 1, r)
;               merge(A, p, q, r)
;           ------------------------------------------
;
; RECEIVES: PARAM_3: 32-bit . . .  DWORD [INDEX_R]
;           PARAM_2: 32-bit . . .  DWORD [INDEX_P]
;           PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
;
; PRE-:     [INDEX_R] has the integer value for the right-most index of [ARRAY].
;           [INDEX_P] has the integer value for the left-most index of [ARRAY].
;           [ARRAY] is a BYTE array.
;
; POST-:    [ARRAY] is modified and then returned fully sorted in ascending order.
;
; CHANGES:  EAX (restored);     EBX (restored);     ECX (restored);     EDX (restored);     EDI (restored);
; ---------------------------------------------------------------------
mergeSort PROC
    enter   12, 0

    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi


    mov     eax, [ebp + 12] ; [INDEX_P]
    mov     edi, [ebp + 8]  ; [ARRAY]

    cmp     eax, [ebp + 16] ; if p < r
    jge     merge_done

    add     eax, [ebp + 16]
    mov     ebx, 2

    cdq

    div     ebx ; q = floor( (p + r) / 2 )

    mov     ebx, [ebp + 12] ; [INDEX_P]
    mov     index_p, ebx

    mov     index_q, eax    ; [INDEX_Q]

    mov     ebx, [ebp + 16] ; [INDEX_R]
    mov     index_r, ebx

    push    index_q     ; q
    push    index_p     ; p
    push    edi         ; A
    call    mergeSort   ; mergeSort(A, p, q)

    inc     index_q
    push    index_r     ; r
    push    index_q     ; q + 1
    push    edi         ; A
    call    mergeSort   ; mergeSort(A, q + 1, r)
    
    dec     index_q

    push    index_r     ; [INDEX_R]
    push    index_q     ; [INDEX_Q]
    push    index_p     ; [INDEX_P]
    push    edi         ; [ARRAY]
    call    merge       ; merge(A, p, q, r)

    merge_done:


    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax

    leave
    ret     12       ; STDCALL
mergeSort ENDP

; ---------------------------------------------------------------------
; NAME:     merge
;
; DESC:     Helper function used by recursive calls to sort sub-arrays of [ARRAY].
;           Completes the following pseudo-code:
;           ------------------------------------------
;           n_1 := q - p + 1
;           n_2 := r - q
;           let L[1 .. n_1 + 1] and R[1 .. n_2 + 1] be new arrays
;           
;           for i = 1 to n_1
;               L[i] := A[p + i - 1]
;
;           for j = 1 to n_2
;               R[j] := A[q + j]
;
;           L[n_1 + 1] := inf
;           R[n_2 + 1] := inf
;
;           i := 1
;           j := 1
;           for k = p to r
;               if L[i] <= R[j]
;                   A[k] := L[i]
;                   i    := i + 1
;               else
;                   A[k] := R[j]
;                   j    := j + 1
;
;           ------------------------------------------
;
; RECEIVES: PARAM_4: 32-bit . . .  DWORD [INDEX_R]
;           PARAM_3: 32-bit . . .  DWORD [INDEX_Q]
;           PARAM_2: 32-bit . . .  DWORD [INDEX_P]
;           PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
; 
; RETURNS:  PARAM_1: 32-bit OFFSET BYTE  [ARRAY]
;
; PRE-:     A global variable 'hHeap' points to a heap memory address available for dynamic memory allocation.
;           [INDEX_R] has the integer value for the right-most index of [ARRAY] sub-array.
;           [INDEX_Q] has the integer value for the mid-point index of [ARRAY] sub-array.
;           [INDEX_P] has the integer value for the left-most index of [ARRAY] sub-array.
;           [ARRAY] is a BYTE array.
;
; POST-:    [ARRAY] is modified and then returned partly sorted in ascending order.
;
; CHANGES:  EAX (restored);     EBX (restored);     EDX (restored);     ECX (restored);     EDI (restored);     ESI (restored);
; ---------------------------------------------------------------------
merge PROC
    enter   20, 0

    push    eax
    push    ebx
    push    edx
    push    ecx
    push    edi
    push    esi
    
    mov     esi, [ebp + 8] ; [ARRAY]

    mov     eax, [ebp + 16] ; [INDEX_Q]
    mov     ebx, [ebp + 12] ; [INDEX_P]

    sub     eax, ebx

    inc     eax

    mov     n_1, eax ; n_1 := q - p + 1

    mov     eax, [ebp + 20] ; [INDEX_R]
    mov     ebx, [ebp + 16] ; [INDEX_Q]

    sub     eax, ebx

    mov     n_2, eax ; n_2 := r - q

    inc     n_1
    inc     n_2

    INVOKE  HeapAlloc, hHeap, HEAP_ZERO_MEMORY, n_1

    cmp     eax, NULL
    je      quit

    mov     A_L, eax ; let L[0 .. n_1]

    INVOKE  HeapAlloc, hHeap, HEAP_ZERO_MEMORY, n_2

    cmp     eax, NULL
    je      quit

    mov     A_R, eax ; let R[0 .. n_2]

    dec     n_2
    dec     n_1

    mov     ecx, 0 ; i
    mov     edi, A_L

    i__to__n_1:
        cmp     ecx, n_1
        jge     i__to__n_1__Done

        mov     eax, [ebp + 12] ; [INDEX_P]

        add     eax, ecx ; p + 1 + i - 1

        mov     bl, [esi + eax] ; A[p + 1 + i - 1]

        mov     [edi + ecx], bl ; L[i] := A[p + i]

        inc     ecx

        jmp     i__to__n_1

    i__to__n_1__Done:
    

    mov     edx, 0 ; j
    mov     edi, A_R

    j__to__n_2:
        cmp     edx, n_2
        jge     j__to__n_2__Done

        mov     eax, [ebp + 16] ; [INDEX_Q]

        add     eax, edx ; q + j
        inc     eax

        mov     bl, [esi + eax] ; A[q + j + 1]

        mov     [edi + edx], bl ; R[j] := A[q + j + 1]

        inc     edx

        jmp     j__to__n_2

    j__to__n_2__Done:


    mov     bl, INF ; inf is defined as '-1' in constants above

    mov     eax, n_2
    mov     [edi + eax], bl ; R[n_2] := inf

    mov     edi, A_L
    mov     eax, n_1
    mov     [edi + eax], bl ; L[n_1] := inf


    mov     ebx, [ebp + 12] ; [INDEX_P]

    mov     index_k, ebx ; k
    mov     ecx, 0       ; i
    mov     edx, 0       ; j

    k__equ__p__to__r:
        mov     ebx, [ebp + 20] ; [INDEX_R]
        cmp     index_k, ebx
        jg      k__equ__p__to__r__Done

        mov     eax, 0
        mov     ebx, 0

        mov     edi, A_L

        mov     bl, [edi + ecx] ; L[i]

        mov     edi, A_R

        mov     al, [edi + edx] ; R[j]

        cmp     al, -1      ;
        je      choose_Li   ;
                            ; - INF cases
        cmp     bl, -1      ;
        je      choose_Rj   ;

        cmp     ebx, eax
        jg      choose_Rj   ; if L[i] <= R[j]

        choose_Li:

        mov     eax, index_k
        mov     [esi + eax], bl ; A[k] := L[i]
        inc     ecx             ; i := i + 1

        inc     index_k
        jmp     k__equ__p__to__r

        choose_Rj:
        
        mov     ebx, index_k
        mov     [esi + ebx], al ; A[k] := R[j]
        inc     edx             ; j := j + 1

        inc     index_k
        jmp     k__equ__p__to__r

    k__equ__p__to__r__Done:

    quit:

    INVOKE HeapFree, hHeap, 0, A_L
    INVOKE HeapFree, hHeap, 0, A_R


    pop     esi
    pop     edi
    pop     ecx
    pop     edx
    pop     ebx
    pop     eax

    leave
    ret     16       ; STDCALL
merge ENDP

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

END main
