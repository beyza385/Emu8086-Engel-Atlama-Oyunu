org 100h
jmp main

; ==== Veriler ==== 
player_x        db 30
player_y_ground db 18
player_y db 18         ; baþlangýç kedi Y konumu
obstacle_x db 75        ; baþlangýç engel X konumu
obstacle_y db 23        ; engel Y konumu (5 satýr aþaðý)        ; engel Y konumu (kedi ile ayný hizada)        ; engel Y konumu (karakterin hemen altýnda)        ; engel Y konumu (karakterin hemen altýnda)        ; engel Y konumu (karakterin üstünde, 1 satýr aþaðý)
game_started db 0       ; oyun baþladý mý?
jump_counter db 0       ; zýplama sayaç
score          dw 0    
score_str   db 'SCORE: ',0; eklenen skor deðiþkeni
clouds:
    db 5, 10    ; satýr 5, sütun 10
    db 3, 40    ; satýr 3, sütun 40
    db 7, 60 ; satýr 7, sütun 60
    db 0, 0     ; son iþaret

; ==== ASCII Kedi ====
stickman:
    db '     # # ',0
    db ' #   ### ',0
    db '# #####  ',0
    db '# #####  ',0
    db '  #   #  ',0  
    db '  #   #  ',0

; ==== Baþlangýç ====
main:
     
    call draw_grass    
    call draw_clouds
    mov [score], 0
    call print_score
    mov ax,0B800h
    mov es,ax
    mov dh,[player_y]
    call draw_player
    call wait_for_space
    mov [game_started],1
    jmp game_loop

; ==== Ýlk Space Bekleme ====
; ==== Ýlk Space Bekleme ====
wait_for_space:
.check:
    mov ah,01h
    int 16h
    jz .check
    mov ah,00h
    int 16h
    cmp al,20h            ; Space tuþu (ASCII 20h)
    jne .check
    ret

; ==== Ana Döngü ====
game_loop:
    call handle_input
    call update_obstacle    ; önce engeli mutlaka güncelle
    call update_jump        ; sonra kedi zýplamasýný uygula
    call check_collision    ; çarpýþma kontrolü
    call delay
    jmp game_loop

; ==== Tuþ Kontrolü ====
handle_input:
    mov ah,01h
    int 16h
    jz .no_input
    mov ah,00h
    int 16h
    cmp al,20h            ; Space mi?
    jne .no_input
    cmp [jump_counter],0
    jne .no_input         ; zaten zýplýyorsa yeni zýplama yok
    mov [jump_counter],6  ; 6 frame zýplama  
.no_input:
    ret

; ==== Zýplama Güncelle ====
update_jump:
    mov al, [jump_counter]
    cmp al, 0
    je .no_jump

    call clear_player

    ; Determine direction: first half ascend, then descend
    cmp al, 3
    jg .ascend
    mov bl, 1            ; descend (y+1)
    jmp .move
.ascend:
    mov bl, -1           ; ascend (y-1)
.move:
    mov al, [player_y]
    add al, bl
    mov [player_y], al
    call draw_player     ; draw cat

    ; Wait at top for a moment and update obstacle
    call delay
    call update_obstacle

    ; Decrement jump counter
    mov al, [jump_counter]
    dec al
    mov [jump_counter], al

    ret

.no_jump:
    ret
    ret
    call draw_player      ; always redraw kedi when not jumping
    ret
    ret
    ret
    ret                
    ret                   

update_obstacle:
    cmp [game_started],1
    jne skip_obs
    mov al,[obstacle_x]
    cmp al,0
    jne continue_update
    ; x=0 ise temizle ve reset
    mov dl,0
    mov dh,[obstacle_y]
    call clear_at
    mov [obstacle_x],75
    mov dl,75
    mov dh,[obstacle_y]
    call draw_at
    ret
continue_update:
    cmp al,1
    jle reset_obstacle
    mov dl,al
    mov dh,[obstacle_y]
    call clear_at
    dec al
    mov [obstacle_x],al
    mov dl,al
    mov dh,[obstacle_y]
    call draw_at
    ret
reset_obstacle:
    mov dl,[obstacle_x]
    mov dh,[obstacle_y]
    call clear_at
    mov [obstacle_x],75
    mov dl,75
    mov dh,[obstacle_y]
    call draw_at 
    mov ax, [score]
    add ax, 25
    mov [score], ax
    call print_score
    call print_score    

    ret
skip_obs:
    ret

; ==== Çarpýþma Kontrol ====
check_collision:
    cmp [game_started],1
    jne .no_collision
    cmp [jump_counter],0    ; zýplýyorsa çarpýþma yok
    jne .no_collision
    mov al,[obstacle_x]
    mov bl,[player_x]
    cmp al,bl
    jne .no_collision
    ; çarpýþma: oyun bitti
    jmp game_over
.no_collision:
    ret

; ==== Oyun Bitti ====
; ==== Çarpýþma Kontrol’den sonra: ====
    jmp game_over      ; normal game_loop’a dönme!

; ==== Oyun Bitti Rutini ====
; ==== Oyun Bitti Rutini ====
game_over:
    call clear_screen

    ; — GAME OVER ortada —
    mov ah,02h
    mov bh,0
    mov dh,12
    mov dl,35
    int 10h

    mov ah,0Eh
    mov al,'G'  
    int 10h
    mov al,'A'  
    int 10h
    mov al,'M'  
    int 10h
    mov al,'E'  
    int 10h
    mov al,' '  
    int 10h
    mov al,'O'  
    int 10h
    mov al,'V'  
    int 10h
    mov al,'E'  
    int 10h
    mov al,'R'  
    int 10h

    ; — ALT SATIRA ÝNMÝÞ KONUMLANDIRMA —
    mov ah,02h
    mov bh,0
    mov dh,13     ; alt satýr
    mov dl,35     ; (80–10)/2 = 35
    int 10h


    ; — “SCORE: ” METNÝNÝ YAZ —
    mov ah,0Eh
    mov al,'S'  
    int 10h
    mov al,'C'  
    int 10h
    mov al,'O'  
    int 10h
    mov al,'R'  
    int 10h
    mov al,'E'  
    int 10h
    mov al,':'  
    int 10h
    mov al,' '  
    int 10h

    ; — ÜÇ HANE BASAMAKLARI HESAPLA VE YAZ — 
    ; score dw 0 olduðundan 16-bit bölme kullanýyoruz
    mov ax,[score]    ; AX = skor
    xor dx,dx
    mov bx,100
    div bx            ; AX = yüzler, DX = kalan (0–99)

    ; yüzler basamaðý
    add al,'0'
    mov ah,0Eh
    int 10h

    ; onlar basamaðý
    mov ax,dx         ; DX = kalan
    xor dx,dx
    mov bx,10
    div bx            ; AX = onlar, DX = birler
    add al,'0'
    mov ah,0Eh
    int 10h

    ; birler basamaðý
    mov al,dl         ; DL = remainder (birler)
    add al,'0'
    mov ah,0Eh
    int 10h

.wait_restart:
    mov ah,01h
    int 16h
    jz .wait_restart
    mov ah,00h
    int 16h
    cmp al,20h
    jne .wait_restart

    ; — Deðiþkenleri sýfýrla ve oyuna dön —
    mov  [score],0
    mov  [game_started],0
    mov  [jump_counter],0
    mov al,[player_y_ground]
    mov [player_y],al
    call clear_screen
    jmp main


; ==== Kedi Çiz ====
draw_player:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si,offset stickman
    mov cx,6
    mov dh,[player_y]
    mov dl,30
.draw_line:
    mov ah,02h
    mov bh,0
    int 10h
.next_char:
    lodsb
    cmp al,0
    je .newline
    mov ah,0Eh
    int 10h
    jmp .next_char
.newline:
    inc dh
    dec cx
    jnz .draw_line
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ==== Kedi Sil ====  
clear_player:  
    push ax  
    push bx  
    push cx  
    push dx  
    mov si,6  
    mov dh,[player_y]  
    mov dl,30  
.clear_line:  
    mov ah,02h  
    mov bh,0  
    int 10h  
    mov ah,0Eh  
    mov al,' '  
    mov cx,9       ; 9 karakter temizle  
.clear_char:  
    int 10h  
    loop .clear_char  
    inc dh  
    dec si  
    jnz .clear_line  
    pop dx  
    pop cx  
    pop bx  
    pop ax  
    ret

; ==== Engel Çiz ====
draw_at:
    push ax
    push bx
    push cx
    push dx
    mov ah,02h
    mov bh,0
    int 10h
    mov ah,0Eh
    mov al,219
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ==== Engel Sil ====
clear_at:
    push ax
    push bx
    push cx
    push dx
    mov ah,02h
    mov bh,0
    int 10h
    mov ah,0Eh
    mov al,' '
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret 

; ==== Skoru Sað Üstte Yazdýr ====
; ==== Skoru Sað Üst Köþede “SCORE: XXX” Biçiminde Yazdýr ====
print_score:
    ; — imleci 0.satýr 71.sütuna taþý —
    mov ah, 02h
    mov bh, 0
    mov dh, 1       ; satýr 1
    mov dl, 66      ; sütun 71–5 = 66
    int 10h

    ; — “SCORE: ” metni —
    mov si, offset score_str
.print_text:
    lodsb
    cmp al, 0
    je .print_digits
    mov ah, 0Eh
    int 10h
    jmp .print_text

.print_digits:
    ; — yüzler basamaðý —
    mov ax, [score]
    mov dx, 0
    mov bx, 100
    div bx               ; AX = yüzler, DX = kalan (0–99)
    add al, '0'
    mov ah, 0Eh
    int 10h

    ; — onlar basamaðý —
    mov ax, dx           ; kalan › AX
    mov dx, 0
    mov bx, 10
    div bx               ; AX = onlar, DX = birler
    add al, '0'
    mov ah, 0Eh
    int 10h

    ; — birler basamaðý —
    mov al, dl           ; birler = kalan’ýn düþük biti
    add al, '0'
    mov ah, 0Eh
    int 10h

    ret

 ; ==== ÇÝMEN ÇÝZ ====  
; 25×80 ekranýn en alt satýrý (row 24) boyunca ',' karakteri yeþil renkle
; ==== Alt Satýrý Çimenle (#) Doldur ====
draw_grass:
    push ax
    push bx
    push cx
    push dx
    mov dh, 24       ; en alt satýr
    xor dl, dl       ; sütun = 0
    mov cx, 80       ; 80 sütun

.grass_loop:
    mov ah, 02h      ; cursor konum
    mov bh, 0 
    mov dl,dl
    int 10h
    
    push cx
    mov ah, 09h      ; text mode yaz
    mov al, '#' 
    mov bh,0
    mov bl,2
    mov cx,1
    int 10h
    pop cx

    inc dl
    loop .grass_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ==== Bulutlarý Çiz ("##" / "####" Bulut Deseni) ====
draw_clouds:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, offset clouds

.next_cloud:
    lodsb            ; AL = satýr
    cmp al, 0
    je .done_clouds
    mov dh, al       ; row

    lodsb            ; AL = sütun
    mov bl, al       ; BL = center sütun

    ; — Bulutun üst kýsmý: iki #, sütun+1 ve sütun+2’de —
    mov dl, bl
    add dl, 1        ; sütun+1
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 0Eh
    mov al, '#'
    int 10h

    inc dl           ; sütun+2
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 0Eh
    mov al, '#'
    int 10h

    ; — Bulutun alt kýsmý: dört #, bir satýr aþaðý ve sütun..sütun+3 arasýnda —
    inc dh           ; alt satýra geç
    mov dl, bl       ; tekrar center sütun
    mov cx, 4        ; 4 karakter

.bcloud_loop:
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 0Eh
    mov al, '#'
    int 10h
    inc dl
    loop .bcloud_loop

    jmp .next_cloud

.done_clouds:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret



; ===== HIZLI EKRAN TEMÝZLE =====
clear_screen:
    mov ah, 06h     ; scroll up
    mov al, 0       ; 0 satýr, tüm ekran
    mov bh, 07h     ; sayfa=0, renk=07h
    mov ch, 0       ; sol üst köþe (row 0, col 0)
    mov cl, 0
    mov dh, 24      ; sað alt köþe (row 24, col 79)
    mov dl, 79
    int 10h
    ret


; ==== Gecikme ====
; ==== Gecikme ====
delay:
    mov cx,05h    ; hýzlandýrýlmýþ engel ve oyun akýþý için döngü sayýsý azaltýldý
.wait:
    nop
    loop .wait
    ret
