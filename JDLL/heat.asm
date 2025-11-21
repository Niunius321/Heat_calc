.data
    rozmiar          dq 100     ; Zmienna przechowuj¹ca liczbê wierszy
    alpha            dq 0.1, 0.1     ; Zmienna przechowuj¹ca liczbê alpha
    time             dq 0.01, 0.01    ; Zmienna przechowuj¹ca liczbê dt
    four             dq 4.0,4.0 ;
    start_map        dq 0       ;
    delta            dq 1.0,1.0
    timee            dq 10.0,10.0
    end_map          dq 0       ;
    adres_tab        dq 0
    adres_tab_new    dq 0
.code
calculate_heat proc
    mov     adres_tab, rcx
    mov     adres_tab_new, rdx
    mov     r14, rcx
    mov     r15, rdx
    movupd  xmm5, [four]
    movupd  xmm6, [delta]
    vmulpd  xmm6,xmm6, xmm6         ; delta*delta
    movupd xmm7, [time]
    movupd xmm8, [alpha]
    vmulpd xmm7,xmm7,xmm8
    mov     r8, [rozmiar]  ; Za³aduj liczba_wierszy do rsi
    sub     rsi, 1
    mov     r9, [rozmiar]    ; Za³aduj liczba_kolumn do rdi
    sub     rdi, 1
    mov     r11, 1          ;Start w mapie kolumny
    mov     r12, 1          ;Start w mapie rzedy
    mov r10, [rozmiar]
    imul r10, 8
    add r14, r10
    add r14, 8
    add r15, r10
    add r15, 8
    sub [rozmiar], 1
    
col_loop:
    cmp     r11, [rozmiar]
    jge     next_row
    cmp     r12, [rozmiar]
    jge     end_calculation
Center:
    
    movupd xmm0, [r14] ; Za³aduj T[i,j]
Up:
   sub r14, r10
   movupd xmm1, [r14] ; Za³aduj T[i-1,j]
   add r14, r10
Down:
    add r14, r10
    movupd xmm2, [r14] ;Za³aduj T[i+1,j]
    sub r14, r10
Left:
    sub r14, 8
    movupd xmm3, [r14]
    add r14, 8
Right:
    add r14, 8
    movupd xmm4, [r14]
    sub r14, 8
Do:
    vaddpd   xmm1, xmm1,xmm2           ; T[i+1,j] += T[i-1,j]
    vaddpd   xmm3, xmm3,xmm4           ; T[i,j+1] += T[i,j-1]
    vmulpd  xmm0,xmm0, xmm5         ;
    vaddpd   xmm1,xmm1,xmm3
    subpd   xmm1, xmm0           ;(temp_x + temp_y -4*T[i][j])
    vdivpd   xmm1,xmm1, xmm6          ; (temp_x + temp_y -4*T[i][j]) / (delta*delta)
    vmulpd   xmm1,xmm1, xmm7           ; (alpha * dt) * [(temp_x + temp_y - 4*T[i][j]) / (delta*delta)]
    vdivpd   xmm0,xmm0, xmm5
    vaddpd   xmm1,xmm1,xmm0
    movupd   [r15], xmm1
    add     r14, 16
    add     r15, 16
    add     r11, 2
    jmp     col_loop

next_row:
    add r14, 16
    add r15, 16
    mov r11, 1
    add r12, 1
    jmp col_loop
end_calculation:
    ret
calculate_heat endp

END