.data
    rozmiar   dq 10      ; Zmienna przechowuj¹ca liczbê wierszy
    alpha            dq 0.1     ; Zmienna przechowuj¹ca liczbê alpha
    time             dq 0.01    ; Zmienna przechowuj¹ca liczbê dt
    four             dq 4.0 ;
    start_map        dq 0       ;
    delta            dq 1.0,1.0
    end_map          dq 0       ;
    adres_tab        dq 0
    adres_tab_new    dq 0
    ; rbx  - wskaŸnik na wiersz
    ; rax  - wskaŸnik na kolumne

.code
calculate_heat proc
    mov rax, r8

    movlpd  xmm5, [four]
    movhpd  xmm5, [four]

    movlpd  xmm6, [delta]
    movhpd  xmm6, [delta]
    mulpd   xmm6, xmm6         ; delta*delta

    movlpd xmm7, [time]
    movhpd xmm7, [time]

    movlpd xmm8, [alpha]
    movhpd xmm8, [alpha]
    mulpd  xmm7,xmm8
    


    imul    r8, 8
    imul    r8, rozmiar
    mov     start_map, r8       ; start_mapy - w¹tek
    

    ;przesuniecie wskaŸnika na pocz¹tek mapy
    add     rcx, start_map
    add     rdx, start_map


    mov     r14,  rcx   ;wskaŸnik na mape
    mov     r15,  rdx   ;wskaŸnik na now¹ mape


    imul    r9, 8
    imul    r9, rozmiar
    mov     end_map, r9         ; koniec mapy - w¹tek
    
    mov     r10, end_map
    sub     r10, start_map

    mov     r9, rcx
    add     r9, r10           ; wskaŸnik na koniec mapy  -> u¿ywany do sprawdzenia koñca obliczeñ mapy


    ; obliczanie 
    mov     r12, [rozmiar]        
    sub     r12, 1              
    movlpd   xmm7, [time]
    movhpd  xmm7, [time]
    movlpd  xmm8, [alpha]
    movhpd  xmm8, [alpha]
    mulpd   xmm7, xmm8         
    
    mov     rsi, qword ptr [rozmiar]  ; Za³aduj liczba_wierszy do rsi
    sub     rsi, 1
    mov     rdi, qword ptr [rozmiar]    ; Za³aduj liczba_kolumn do rdi
    sub     rdi, 1


col_loop:
    cmp     r14, r9
    jge     end_calculation

    cmp     rbx, r12 ; Jeœli rax >= liczba_kolumn, koñczymy pêtlê
    jge     end_row

    ; Sprawdzanie, czy element znajduje siê na krawêdzi
    cmp     rax, 0              ; Jeœli wiersz == 0 (pierwszy wiersz), pomijamy
    je      skip_calculation
    cmp     rax, rsi            ; Jeœli wiersz == liczba_wierszy - 1 (ostatni wiersz), pomijamy
    je      skip_calculation
    cmp     rbx, 0              ; Jeœli kolumna == 0 (pierwsza kolumna), pomijamy
    je      skip_calculation
    cmp     rbx, rdi             ; Jeœli kolumna == liczba_kolumn - 1 (ostatnia kolumna), pomijamy
    je      skip_calculation

First_value:
    ; Pobierz wartoœæ T[i,j] - Odczytanie wartoœci z tablicy (T[i,j])
    movlpd   xmm0, qword ptr [r14]   ; Za³aduj T[i,j] do xmm2

    ; Obliczanie adresów s¹siadów
    ; T[i+1,j] - s¹siad poni¿ej
    xor     r10, r10
    add     r10, 1
    imul    r10, [rozmiar]
    imul    r10, 8
    add     r14, r10
    movlpd   xmm1, qword ptr [r14]  ; Za³aduj T[i+1,j]
    sub     r14, r10              ; Przywróæ wskaŸnik

    ; T[i-1,j] - s¹siad powy¿ej
    sub     r14, r10
    movlpd   xmm2, qword ptr [r14]  ; Za³aduj T[i-1,j]
    add     r14, r10              ; Przywróæ wskaŸnik
    ; T[i,j+1] - s¹siad po prawej
    xor     r10, r10
    add     r10, 8
    add     r14, r10
    movlpd   xmm3, qword ptr [r14]  ; Za³aduj T[i,j+1]
    sub     r14, r10              ; Przywróæ wskaŸnik

    ; T[i,j-1] - s¹siad po lewej
    sub     r14, r10
    movlpd   xmm4, qword ptr [r14]  ; Za³aduj T[i,j-1]
    add     r14, r10              ; Przywróæ wskaŸnik
    
Second_value:
    add r14, 8
    ; Pobierz wartoœæ T[i,j] - Odczytanie wartoœci z tablicy (T[i,j])
    movhpd   xmm0, qword ptr [r14]   ; Za³aduj T[i,j] do xmm2

    ; Obliczanie adresów s¹siadów
    ; T[i+1,j] - s¹siad poni¿ej
    xor     r10, r10
    add     r10, 1
    imul    r10, [rozmiar]
    imul    r10, 8
    add     r14, r10
    movhpd   xmm1, qword ptr [r14]  ; Za³aduj T[i+1,j]
    sub     r14, r10              ; Przywróæ wskaŸnik

    ; T[i-1,j] - s¹siad powy¿ej
    sub     r14, r10
    movhpd   xmm2, qword ptr [r14]  ; Za³aduj T[i-1,j]
    add     r14, r10              ; Przywróæ wskaŸnik
    ; T[i,j+1] - s¹siad po prawej
    xor     r10, r10
    add     r10, 8
    add     r14, r10
    movhpd   xmm3, qword ptr [r14]  ; Za³aduj T[i,j+1]
    sub     r14, r10              ; Przywróæ wskaŸnik

    ; T[i,j-1] - s¹siad po lewej
    sub     r14, r10
    movhpd   xmm4, qword ptr [r14]  ; Za³aduj T[i,j-1]
    add     r14, r10              ; Przywróæ wskaŸnik

    sub r14, 8
Do:
    ; Obliczanie ró¿nicy Laplace'a: T[i,j] = T[i,j] + T[i+1,j] + T[i-1,j] + T[i,j+1] + T[i,j-1]
    addpd   xmm1, xmm2           ; T[i+1,j] += T[i-1,j]
    addpd   xmm3, xmm4           ; T[i,j+1] += T[i,j-1]

    ; T[i,j] = T[i,j] + alpha * dt * Laplace(T[i,j])

    mulpd   xmm0, xmm5         ;
    addpd   xmm1, xmm3
    subpd   xmm1, xmm0           ;(temp_x + temp_y -4*T[i][j])
    divpd   xmm1, xmm6          ; (temp_x + temp_y -4*T[i][j]) / (delta*delta)
    mulpd   xmm1, xmm7           ; (alpha * dt) * [(temp_x + temp_y - 4*T[i][j]) / (delta*delta)]
    divpd   xmm0, xmm5
    addpd   xmm1, xmm0
    ; Zapisz zmodyfikowan¹ wartoœæ T[i,j]
    movlpd   qword ptr [r15], xmm1
    add     r14, 8
    add     r15, 8
    movhpd  qword ptr [r15], xmm1
    add     r14, 8
    add     r15, 8
    add     rbx,2
    jmp     col_loop

skip_calculation:
    ; PrzejdŸ do kolejnego elementu w tablicy (przesuñ wskaŸnik o 8 bajtów)
    movsd   xmm0, qword ptr [r14]
    movsd   qword ptr [r15], xmm0
    add     r14, 8
    add     r15, 8
    inc     rbx
    jmp     col_loop

end_row:
    movsd   xmm12, qword ptr [r14]
    movsd   qword ptr [r15], xmm12
    ; PrzejdŸ do nastêpnego wiersza
    inc     rax                   ; Zwiêksz licznik wierszy
    add     r14, 8
    add     r15, 8
    xor     rbx, rbx              ; Zresetuj licznik kolumn
    jmp     col_loop              ; Kontynuuj pêtlê po wierszach

end_calculation:
    ret
calculate_heat endp

END