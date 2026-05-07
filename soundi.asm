.8086
.model tiny
.code
org 100h

start:
    jmp main

;==========================================================
; TABLA DE SONIDOS - Frecuencias y Duraciones
;==========================================================
sound_table:
    ; Función 01h - Sonido de pieza colocada
    dw 420, 50      ; Frecuencia: 420Hz, Duración: 50ms
    
    ; Función 02h - Sonido de empate parte 1
    dw 659, 200     ; Mi5 - 659Hz, 200ms
    
    ; Función 03h - Sonido de empate parte 2  
    dw 523, 200     ; Do5 - 523Hz, 200ms
    
    ; Función 04h - Sonido de empate parte 3
    dw 440, 300     ; La4 - 440Hz, 300ms
    
    ; Función 05h - Sonido de victoria parte 1
    dw 523, 150     ; Do5 - 523Hz, 150ms
    
    ; Función 06h - Sonido de victoria parte 2
    dw 659, 150     ; Mi5 - 659Hz, 150ms
    
    ; Función 07h - Sonido de victoria parte 3
    dw 784, 400     ; Sol5 - 784Hz, 400ms

SoundISR PROC FAR
    ;======================================================
    ; ISR PRINCIPAL
    ;======================================================

    push ax
    push bx
    push cx
    push dx
    push ds
    
    push cs
    pop ds
    
    ; Verificar rango válido de funciones (01h-07h)
    cmp ah, 01h
    jb invalid_function
    cmp ah, 07h
    ja invalid_function
    
    ; Calcular índice en tabla, (AH-1)*4
    mov bl, ah
    dec bl
    mov bh, 0
    shl bx, 1
    shl bx, 1
    
    ; Obtener frecuencia y duración de la tabla
    mov si, offset sound_table
    add si, bx                          ; SI apunta al elemento correcto
    mov ax, [si]                        ; Frecuencia
    mov cx, [si+2]                      ; Duración en ms
    
    ; Reproducir el sonido
    call play_tone
    
invalid_function:
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    iret
SoundISR ENDP

play_tone PROC
    ;================================================================
    ; Reproduce un tono con frecuencia y duración específicas
    ; Entrada: AX = frecuencia en Hz, CX = duración en ms
    ;================================================================
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Verificar frecuencia válida
    test ax, ax
    jz tone_exit
    
    mov si, ax
    
    ; Calcular divisor para el timer: 1193180 / frecuencia
    mov dx, 12h                     ; Parte alta de 1193180 (0x123456)
    mov ax, 34DCh                   ; Parte baja de 1193180
    div si                          ; AX = 1193180 / frecuencia
    mov bx, ax
    
    ; Configurar timer del PC speaker (canal 2)
    mov al, 0B6h                    ; Comando: canal 2, modo 3, binario
    out 43h, al                     ; Puerto de control del timer
    
    ; Enviar divisor de frecuencia
    mov al, bl                      ; Byte bajo
    out 42h, al                     ; Canal 2 data port
    mov al, bh                      ; Byte alto
    out 42h, al                     ; Canal 2 data port
    
    ; Activar altavoz
    in al, 61h                      ; Leer puerto del altavoz
    or al, 03h                      ; Activar gate y speaker
    out 61h, al                     ; Activar
    
    ; Delay
    push ax
    push bx
    
    ; Convertir ms a ciclos
    mov ax, cx          
    mov bx, 1000        
    mul bx                          ; AX = ms * 1000
    mov cx, ax                      ; CX = contador total
    
    ; Si es muy poco, usar mínimo
    cmp cx, 5000
    jae delay_ok
    mov cx, 5000                    ; Mínimo de ciclos
    
delay_ok:
delay_loop:
    push cx
    mov cx, 100                     ; Bucle interno
inner_loop:
    nop
    nop
    nop
    nop
    loop inner_loop
    pop cx
    dec cx
    jnz delay_loop                  ; Bucle externo
    
    pop bx
    pop ax
    
    ; Desactivar altavoz
    in al, 61h
    and al, 0FCh
    out 61h, al
    
tone_exit:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
play_tone ENDP

;====================================================================
; DATOS PARA ALMACENAR VECTOR ANTERIOR
;====================================================================
old_int80_offset    dw 0
old_int80_segment   dw 0

; Marca el final de la parte residente
end_resident:

;====================================================================
; CÓDIGO DE INSTALACIÓN (NO RESIDENTE)
;====================================================================
install_msg db 0Dh, 0Ah, "Sistema de Sonidos v2.0 instalado correctamente", 0Dh, 0Ah
           db "Funciones disponibles via INT 80h:", 0Dh, 0Ah
           db "  AH=01h - Sonido de pieza colocada", 0Dh, 0Ah
           db "  AH=02h - Sonido de empate (parte 1)", 0Dh, 0Ah
           db "  AH=03h - Sonido de empate (parte 2)", 0Dh, 0Ah
           db "  AH=04h - Sonido de empate (parte 3)", 0Dh, 0Ah
           db "  AH=05h - Sonido de victoria (parte 1)", 0Dh, 0Ah
           db "  AH=06h - Sonido de victoria (parte 2)", 0Dh, 0Ah
           db "  AH=07h - Sonido de victoria (parte 3)", 0Dh, 0Ah
           db 0Dh, 0Ah, '$'

error_msg  db 0Dh, 0Ah, "Error: No se pudo instalar el sistema de sonidos", 0Dh, 0Ah, '$'

main:
    ; Establecer segmentos
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    ; Verificar si ya está instalado
    call check_installation
    jc already_installed
    
    ; Obtener vector actual de INT 80h
    mov ax, 3580h
    int 21h
    mov old_int80_offset, bx
    mov old_int80_segment, es
    
    ; Instalar nueva ISR
    mov ax, 2580h
    mov dx, offset SoundISR
    int 21h
    jc install_error
    
    ; Mostrar mensaje de éxito
    mov dx, offset install_msg
    mov ah, 09h
    int 21h
    
    ; Calcular paragraphs necesarios
    mov ax, offset end_resident
    add ax, 15                      ; Redondear hacia arriba
    mov cl, 4
    shr ax, cl                      ; Dividir por 16 para obtener paragraphs
    
    ; Terminar y quedar residente
    mov dx, ax
    mov ax, 3100h                   ; Terminar con código 0, quedar residente
    int 21h

already_installed:
    mov dx, offset already_msg
    mov ah, 09h
    int 21h
    mov ax, 4C01h                   ; Terminar con error
    int 21h

install_error:
    mov dx, offset error_msg
    mov ah, 09h
    int 21h
    mov ax, 4C01h                   ; Terminar con error
    int 21h

already_msg db "Sistema de sonidos ya instalado", 0Dh, 0Ah, 24h

check_installation PROC
    push ax
    push bx
    push es
    
    ; Obtener vector actual de INT 80h
    mov ax, 3580h
    int 21h
    
    ; Verificar si apunta a nuestro código
    ; Comparamos los primeros bytes de la ISR
    mov ax, es:[bx]
    cmp ax, word ptr cs:SoundISR
    je is_installed
    
    clc                     ; CF=0, no instalado
    jmp check_exit
    
    is_installed:
        stc                     ; CF=1, ya instalado
        
    check_exit:
        pop es
        pop bx
        pop ax
        ret
check_installation ENDP

end start