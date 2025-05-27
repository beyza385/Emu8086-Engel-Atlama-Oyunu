org 100h
jmp main

; ==== Veriler ==== 
player_x        db 30
player_y_ground db 18
player_y db 18         ; ba�lang�� kedi Y konumu
obstacle_x db 75        ; ba�lang�� engel X konumu
obstacle_y db 23        ; engel Y konumu (5 sat�r a�a��)        ; engel Y konumu (kedi ile ayn� hizada)        ; engel Y konumu (karakterin hemen alt�nda)        ; engel Y konumu (karakterin hemen alt�nda)        ; engel Y konumu (karakterin �st�nde, 1 sat�r a�a��)
game_started db 0       ; oyun ba�lad� m�?
jump_counter db 0       ; z�plama saya�
score          dw 0    
score_str   db 'SCORE: ',0; eklenen skor de�i�keni
clouds:
    db 5, 10    ; sat�r 5, s�tun 10
    db 3, 40    ; sat�r 3, s�tun 40
    db 7, 60 ; sat�r 7, s�tun 60
    db 0, 0     ; son i�aret

; ==== ASCII Kedi ====
stickman:
    db '     # # ',0
    db ' #   ### ',0
    db '# #####  ',0
    db '# #####  ',0
    db '  #   #  ',0  
    db '  #   #  ',0

; ==== Ba�lang�� ====
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

; ==== �lk Space Bekleme ====
; ==== �lk Space Bekleme ====
wait_for_space:
.check:
    mov ah,01h
    int 16h
    jz .check
    mov ah,00h
    int 16h
    cmp al,20h            ; Space tu�u (ASCII 20h)
    jne .check
    ret

; ==== Ana D�ng� ====
game_loop:
    call handle_input
    call update_obstacle    ; �nce engeli mutlaka g�ncelle
    call update_jump        ; sonra kedi z�plamas�n� uygula
    call check_collision    ; �arp��ma kontrol�
    call delay
    jmp game_loop

; ==== Tu� Kontrol� ====
handle_input:
    mov ah,01h
    int 16h
    jz .no_input
    mov ah,00h
    int 16h
    cmp al,20h            ; Space mi?
    jne .no_input
    cmp [jump_counter],0
    jne .no_input         ; zaten z�pl�yorsa yeni z�plama yok
    mov [jump_counter],6  ; 6 frame z�plama  
.no_input:
    ret

; ==== Z�plama G�ncelle ====
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

; ==== �arp��ma Kontrol ====
check_collision:
    cmp [game_started],1
    jne .no_collision
    cmp [jump_counter],0    ; z�pl�yorsa �arp��ma yok
    jne .no_collision
    mov al,[obstacle_x]
    mov bl,[player_x]
    cmp al,bl
    jne .no_collision
    ; �arp��ma: oyun bitti
    jmp game_over
.no_collision:
    ret

; ==== Oyun Bitti ====
; ==== �arp��ma Kontrol�den sonra: ====
    jmp game_over      ; normal game_loop�a d�nme!

; ==== Oyun Bitti Rutini ====
; ==== Oyun Bitti Rutini ====
game_over:
    call clear_screen

    ; � GAME OVER ortada �
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

    ; � ALT SATIRA �NM�� KONUMLANDIRMA �
    mov ah,02h
    mov bh,0
    mov dh,13     ; alt sat�r
    mov dl,35     ; (80�10)/2 = 35
    int 10h


    ; � �SCORE: � METN�N� YAZ �
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

    ; � �� HANE BASAMAKLARI HESAPLA VE YAZ � 
    ; score dw 0 oldu�undan 16-bit b�lme kullan�yoruz
    mov ax,[score]    ; AX = skor
    xor dx,dx
    mov bx,100
    div bx            ; AX = y�zler, DX = kalan (0�99)

    ; y�zler basama��
    add al,'0'
    mov ah,0Eh
    int 10h

    ; onlar basama��
    mov ax,dx         ; DX = kalan
    xor dx,dx
    mov bx,10
    div bx            ; AX = onlar, DX = birler
    add al,'0'
    mov ah,0Eh
    int 10h

    ; birler basama��
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

    ; � De�i�kenleri s�f�rla ve oyuna d�n �
    mov  [score],0
    mov  [game_started],0
    mov  [jump_counter],0
    mov al,[player_y_ground]
    mov [player_y],al
    call clear_screen
    jmp main


; ==== Kedi �iz ====
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

; ==== Engel �iz ====
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

; ==== Skoru Sa� �stte Yazd�r ====
; ==== Skoru Sa� �st K��ede �SCORE: XXX� Bi�iminde Yazd�r ====
print_score:
    ; � imleci 0.sat�r 71.s�tuna ta�� �
    mov ah, 02h
    mov bh, 0
    mov dh, 1       ; sat�r 1
    mov dl, 66      ; s�tun 71�5 = 66
    int 10h

    ; � �SCORE: � metni �
    mov si, offset score_str
.print_text:
    lodsb
    cmp al, 0
    je .print_digits
    mov ah, 0Eh
    int 10h
    jmp .print_text

.print_digits:
    ; � y�zler basama�� �
    mov ax, [score]
    mov dx, 0
    mov bx, 100
    div bx               ; AX = y�zler, DX = kalan (0�99)
    add al, '0'
    mov ah, 0Eh
    int 10h

    ; � onlar basama�� �
    mov ax, dx           ; kalan � AX
    mov dx, 0
    mov bx, 10
    div bx               ; AX = onlar, DX = birler
    add al, '0'
    mov ah, 0Eh
    int 10h

    ; � birler basama�� �
    mov al, dl           ; birler = kalan��n d���k biti
    add al, '0'
    mov ah, 0Eh
    int 10h

    ret

 ; ==== ��MEN ��Z ====  
; 25�80 ekran�n en alt sat�r� (row 24) boyunca ',' karakteri ye�il renkle
; ==== Alt Sat�r� �imenle (#) Doldur ====
draw_grass:
    push ax
    push bx
    push cx
    push dx
    mov dh, 24       ; en alt sat�r
    xor dl, dl       ; s�tun = 0
    mov cx, 80       ; 80 s�tun

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

; ==== Bulutlar� �iz ("##" / "####" Bulut Deseni) ====
draw_clouds:
    push ax
    push bx
    push cx
    push dx
    push si
    mov si, offset clouds

.next_cloud:
    lodsb            ; AL = sat�r
    cmp al, 0
    je .done_clouds
    mov dh, al       ; row

    lodsb            ; AL = s�tun
    mov bl, al       ; BL = center s�tun

    ; � Bulutun �st k�sm�: iki #, s�tun+1 ve s�tun+2�de �
    mov dl, bl
    add dl, 1        ; s�tun+1
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 0Eh
    mov al, '#'
    int 10h

    inc dl           ; s�tun+2
    mov ah, 02h
    mov bh, 0
    int 10h
    mov ah, 0Eh
    mov al, '#'
    int 10h

    ; � Bulutun alt k�sm�: d�rt #, bir sat�r a�a�� ve s�tun..s�tun+3 aras�nda �
    inc dh           ; alt sat�ra ge�
    mov dl, bl       ; tekrar center s�tun
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



; ===== HIZLI EKRAN TEM�ZLE =====
clear_screen:
    mov ah, 06h     ; scroll up
    mov al, 0       ; 0 sat�r, t�m ekran
    mov bh, 07h     ; sayfa=0, renk=07h
    mov ch, 0       ; sol �st k��e (row 0, col 0)
    mov cl, 0
    mov dh, 24      ; sa� alt k��e (row 24, col 79)
    mov dl, 79
    int 10h
    ret


; ==== Gecikme ====
; ==== Gecikme ====
delay:
    mov cx,05h    ; h�zland�r�lm�� engel ve oyun ak��� i�in d�ng� say�s� azalt�ld�
.wait:
    nop
    loop .wait
    ret
