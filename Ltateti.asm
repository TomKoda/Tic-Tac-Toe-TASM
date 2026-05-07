.8086
.model small
.stack 100h
.data
    msg_esc             db 'ESC para salir', 24h
    msg_enter           db 'ENTER para nueva partida  ',24h
    
    msg_jugador1        db 'Turno: Jugador 1', 24h
    msg_jugador2        db 'Turno: Jugador 2', 24h
    
    msg_ocupada         db 'Casilla ocupada!', 24h
    
    msg_no_mouse        db 'Mouse no detectado.', 24h

    msg_final_1         db 'Gana el Jugador 1',24h
    msg_final_2         db 'Gana el Jugador 2',24h
    msg_final_empate    db 'Partida empatada',24h

    msg_final           db 0

    sound_flag          db 0

    mouse_x             dw 0
    mouse_y             dw 0
    
    click_anterior      db 0           ; falg para detectar nuevo click
    casilla_actual      db 255         ; 255 = fuera del tablero
    jugador_actual      db 1           ; 1 = Jugador 1, 2 = Jugador 2
    
    
    ; 0 = vacía, 1 = (Jugador 1), 2 = (Jugador 2)
    tablero_estado      db 9 dup(0)

    ; Constantes del tablero
    TABLERO_X_INI       equ 100        ; X inicial del tablero
    TABLERO_Y_INI       equ 40         ; Y inicial del tablero
    TABLERO_ANCHO       equ 120        ; Ancho total del tablero
    TABLERO_ALTO        equ 120        ; Alto total del tablero
    CASILLA_SIZE        equ 40         ; Tamaño de cada casilla
.code
    ; ==================== INICIALIZACION ====================

    public inicializar_grafico
    public inicializar_mouse
    public dibujar_tablero
    public inicializar_variables

    inicializar_grafico PROC
        ;==========================================================================================
        ; Inicializa el modo gráfico 13h (VGA 320x200, 256 colores).
        ;
        ; Notas:
        ;   - Este modo permite acceso directo a memoria de video en A000h.
        ;   - Es necesario llamarlo antes de dibujar píxeles o líneas.
        ;==========================================================================================
        
        push ax
        xor ax, ax

        mov ax, 0013h
        int 10h

        pop ax

        ret
    inicializar_grafico ENDP

    inicializar_mouse PROC
        ;==========================================================================================
        ; Inicializa el mouse y muestra el puntero en pantalla (modo gráfico).
        ;
        ; Devuelve:
        ;   Muestra el puntero del mouse si el mouse está disponible.
        ;   AX = FFFFh si el mouse fue detectado.
        ;
        ; Notas:
        ;   - Debe llamarse una vez al inicio para habilitar el uso del mouse.
        ;   - El puntero puede moverse y detectar clics automáticamente desde aquí.
        ;==========================================================================================

        push ax
        xor ax, ax
        push bx                                  ; Por retorno de int 33h
        xor bx, bx

        mov ax, 0000h                            ; Resetear mouse
        int 33h        
        
        cmp ax, 0FFFFh                           ; Verificar si el mouse está disponible
        jne no_mouse
        
        mov ax, 0001h                            ; Mostrar cursor del mouse
        int 33h

        pop bx
        pop ax
        ret
    no_mouse:
        ; Si no se detecta el mouse
        mov ax, 0003h                            ; Restaurar modo texto    
        int 10h
        
        mov ah, 09h
        mov dx, offset msg_no_mouse              ; Muestra mensaje de error
        int 21h
        
        mov ax, 4C00h                            ; Termina el programa.
        int 21h
    inicializar_mouse ENDP

    dibujar_tablero PROC
        ;==========================================================================================
        ; Dibuja el tablero principal en pantalla, linea a linea.
        ;
        ; Devuelve:
        ;   El tablero aparece dibujado en modo gráfico (2 líneas horizontales, 2 verticales y marco exterior).
        ;
        ; Dependencias:
        ;   dibujar_linea_horizontal
        ;   dibujar_linea_vertical
        ;   Constantes:
        ;       - TABLERO_X_INI = Coordenada X inicial del tablero.
        ;       - TABLERO_Y_INI = Coordenada Y inicial del tablero.
        ;       - TAM_CASILLA   = Tamaño de cada casilla del tablero.
        ;
        ; Notas:
        ;   - El tablero consta de una grilla 3x3, dividiendo el área en 9 casillas.
        ;   - El tablero tiene dimensiones de 120x120 pixeles.
        ;   - Cada casilla tiene dimensiones de 40x40 pixeles.
        ;   - Utiliza líneas verticales y horizontales espaciadas según el tamaño de casilla.
        ;==========================================================================================
        
        ; LÍNEAS VERTICALES INTERNAS ( Columnas )

        ; Primera línea vertical interna (X = 140)
        push TABLERO_X_INI + CASILLA_SIZE                  ; X = 100 + 40 = 140
        push TABLERO_Y_INI                                 ; Y inicial = 40
        push TABLERO_ALTO                                  ; Longitud = 120
        call dibujar_linea_vertical
        
        ; Segunda línea vertical interna (X = 180)
        push TABLERO_X_INI + (CASILLA_SIZE * 2)            ; X = 100 + 80 = 180
        push TABLERO_Y_INI                                 ; Y inicial = 40
        push TABLERO_ALTO                                  ; Longitud = 120
        call dibujar_linea_vertical
        
        ;======================================================================

        ; LÍNEAS HORIZONTALES INTERNAS ( filas )

        ; Primera línea horizontal interna (Y = 80)
        push TABLERO_X_INI                                 ; X inicial = 100
        push TABLERO_Y_INI + CASILLA_SIZE                  ; Y = 40 + 40 = 80
        push TABLERO_ANCHO                                 ; Longitud = 120
        call dibujar_linea_horizontal
        
        ; Segunda línea horizontal interna (Y = 120)       
        push TABLERO_X_INI                                 ; X inicial = 100
        push TABLERO_Y_INI + (CASILLA_SIZE * 2)            ; Y = 40 + 80 = 120
        push TABLERO_ANCHO                                 ; Longitud = 120
        call dibujar_linea_horizontal
        
        ;======================================================================

        ; MARCO DEL TABLERO (Lo dejamos?)
        
        ; Línea superior externa
        push TABLERO_X_INI                                 ; X inicial = 100
        push TABLERO_Y_INI                                 ; Y = 40
        push TABLERO_ANCHO                                 ; Longitud = 120
        call dibujar_linea_horizontal
        
        ; Línea inferior externa
        push TABLERO_X_INI                                 ; X inicial = 100
        push TABLERO_Y_INI + TABLERO_ALTO                  ; Y = 40 + 120 = 160
        push TABLERO_ANCHO                                 ; Longitud = 120
        call dibujar_linea_horizontal
        
        ; Línea izquierda externa
        push TABLERO_X_INI                                 ; X = 100
        push TABLERO_Y_INI                                 ; Y inicial = 40
        push TABLERO_ALTO                                  ; Longitud = 120
        call dibujar_linea_vertical
        
        ; Línea derecha externa
        push TABLERO_X_INI + TABLERO_ANCHO                 ; X = 100 + 120 = 220
        push TABLERO_Y_INI                                 ; Y inicial = 40
        push TABLERO_ALTO                                  ; Longitud = 120
        call dibujar_linea_vertical
    
        ret
    dibujar_tablero ENDP

    inicializar_variables proc
        ;==========================================================================================
        ; Reinicia el las variables con su valor por defecto 
        ; y limpia la pantalla para nuevo tablero
        ;==========================================================================================
        push ax
        push bx
        push cx
        push dx

        mov mouse_x, 0
        mov mouse_y, 0
        mov msg_final, 0
        mov sound_flag, 0
        mov click_anterior, 0
        mov casilla_actual, 255
        mov jugador_actual, 1

        mov cx, 3100
        limpiar_pantalla_loop:
            mov ah, 2
            mov dl, " "
            int 21h
        loop limpiar_pantalla_loop

        mov bx, 0
        tablero_estado_loop:
            mov tablero_estado[bx], 0
            inc bx
            cmp bx, 8 
            ja fin_inicializar_variables
        jmp tablero_estado_loop
        
        fin_inicializar_variables:
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    inicializar_variables endp

    ; ==================== MENSAJES / INSTRUCCIONES ====================
    
    public mostrar_instrucciones
    public mostrar_turno_actual

    limpiar_linea proc
        ;==========================================================================================
        ; Limpia una línea de texto en pantalla imprimiendo espacios en blanco.
        ;
        ; Recibe (por stack):
        ;   [bp+4] = Cantidad de caracteres a imprimir.
        ;
        ; Devuelve:
        ;   - Imprime espacios (20h) en la posición actual del cursor.
        ;
        ; Notas:
        ;   - No cambia la posición del cursor al inicio de la línea.
        ;   - Requiere posicionar el cursor previamente con otra función si se desea borrar una línea específica.
        ;==========================================================================================
        push bp
        mov bp, sp

        push cx
        xor cx, cx

        mov cx, ss:[bp+4]

        limpiar_linea_loop:
            mov ah, 02h
            mov dl, ' '
            int 21h
        loop limpiar_linea_loop

        pop cx
        pop bp
        ret 2
    limpiar_linea endp

    mostrar_instrucciones PROC
        ;==========================================================================================
        ; Muestra el mensaje de instrucciones en la parte superior de la pantalla.
        ;
        ; Devuelve:
        ;   Muestra el texto "Presiona ESC para salir" en pantalla.
        ;
        ; Dependencias:
        ;   msg_esc → Cadena con mensaje a mostrar.  
        ;==========================================================================================

        push ax
        xor ax, ax
        push bx
        xor bx, bx
        push dx
        xor dx, dx

        ; Posicionar cursor en la parte superior
        mov ah, 02h
        mov bh, 0
        mov dh, 1           ; Fila 1
        mov dl, 2           ; Columna 2 
        int 10h
        
        ; Mostrar mensaje de instrucciones
        mov ah, 09h
        mov dx, offset msg_esc
        int 21h
        
        pop dx
        pop bx
        pop ax
        ret
    mostrar_instrucciones ENDP

    mostrar_turno_actual PROC
        ;==========================================================================================
        ; Muestra en pantalla el turno actual del jugador.
        ; 
        ; Devuelve:
        ;   - Imprime en pantalla el mensaje "Turno actual: Jugador 1" o "Turno actual: Jugador 2".
        ;
        ; Dependencias:
        ;   - turno_actual →  1 / 2
        ;   - msg_jugador1 → 'Turno: Jugador 1', 24h
        ;   - msg_jugador2 → 'Turno: Jugador 2', 24h
        ;==========================================================================================

        push ax
        xor ax, ax
        push bx
        xor bx, bx
        push dx
        xor dx, dx

        ; Posicionar cursor para mostrar el turno
        mov ah, 02h
        mov bh, 0
        mov dh, 3            ; Fila 3
        mov dl, 12           ; Columna 12
        int 10h
        
        ; Limpiar la línea
        push 20
        call limpiar_linea
        
        ; Reposicionar cursor
        mov ah, 02h
        mov bh, 0
        mov dh, 3            ; Fila 3
        mov dl, 12           ; Columna 12
        int 10h
        
        ; Mostrar mensaje según el jugador actual
        cmp jugador_actual, 1
        je mostrar_jugador1
        
        ; Mostrar Jugador 2
        mov ah, 09h
        mov dx, offset msg_jugador2
        int 21h
        jmp fin_mostrar_turno
        
    mostrar_jugador1:
        ; Mostrar Jugador 1
        mov ah, 09h
        mov dx, offset msg_jugador1
        int 21h
        
    fin_mostrar_turno:
        pop dx
        pop bx
        pop ax
        ret
    mostrar_turno_actual ENDP

    mostrar_mensaje_final PROC
        ;==========================================================================================
        ; Muestra un mensaje informando que la casilla seleccionada ya está ocupada.
        ;==========================================================================================
        push ax
        push bx
        push cx
        push dx

        ; Posicionar cursor para mostrar mensaje
        mov ah, 02h
        mov bh, 0
        mov dh, 21           ; Fila 21
        mov dl, 12           ; Columna 12
        int 10h
        
        cmp msg_final, 1
        je msg_gana_1
        cmp msg_final, 2
        je msg_gana_2
        cmp msg_final, 3
        je empate
        
        push 30
        call limpiar_linea
        
        ; Reposicionar cursor
        mov ah, 02h
        mov bh, 0
        mov dh, 21
        mov dl, 12
        int 10h

        jmp fin_mostrar_mensaje_final_continua

        msg_gana_1:
            ; Mostrar mensaje Gana Jugador 1
            mov ah, 09h
            mov dx, offset msg_final_1
            int 21h

            cmp sound_flag, 1
            je fin_mostrar_mensaje_final

            call victory_sound
            call short_pause
            call victory_sound

            mov sound_flag, 1

            jmp fin_mostrar_mensaje_final
        msg_gana_2:
            ; Mostrar mensaje Gana Jugador 2
            mov ah, 09h
            mov dx, offset msg_final_2
            int 21h

            cmp sound_flag, 1
            je fin_mostrar_mensaje_final

            call victory_sound
            call short_pause
            call victory_sound

            mov sound_flag, 1

            jmp fin_mostrar_mensaje_final
        empate:
            ; Mostrar mensaje Empate
            mov ah, 09h
            mov dx, offset msg_final_empate
            int 21h

            cmp sound_flag, 1
            je fin_mostrar_mensaje_final

            call draw_sound
            call short_pause
            call draw_sound

            mov sound_flag, 1

        fin_mostrar_mensaje_final:
            
            mov ah, 02h
            mov bh, 0
            mov dh, 3
            mov dl, 2
            int 10h

            mov ah, 09h
            mov dx, offset msg_enter
            int 21h
            
        fin_mostrar_mensaje_final_continua:
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    mostrar_mensaje_final ENDP

    ; ==================== PROCEDIMIENTOS ====================

    public verificar_mouse

    verificar_mouse PROC
        ;==========================================================================================
        ; Verifica la interacción del jugador mediante el mouse.
        ;
        ; Dependencias:
        ;   - coordenadas_a_casilla
        ;   - verificar_casilla_libre
        ;   - marcar_casilla
        ;   - dibujar_x_en_casilla
        ;   - mostrar_turno_actual
        ;   - mostrar_mensaje_final
        ;   - piece_sound
        ;
        ; Notas:
        ;   - La coordenada X del mouse debe dividirse por 2 debido a la resolución lógica.
        ;   - Si la partida finalizó (msg_final ≠ 0), no se realiza ninguna acción.
        ;==========================================================================================
        
        cmp msg_final, 0
        jne fin_verificar

        ; Obtener estado del mouse
        mov ax, 0003h
        int 33h

        shr cx, 1           ; Dividir coordenada X por 2

        ; Guardar coordenadas corregidas
        mov mouse_x, cx
        mov mouse_y, dx

        ;==========================================================================================

        ; Verificar si se presionó el botón izquierdo
        and bx, 1
        cmp bx, 0
        je no_click
        
        ; Verificar si es un nuevo click (evitar repetición)
        cmp click_anterior, 1
        je no_click

        ; Marcar que hay un click activo
        mov click_anterior, 1

        ;==========================================================================================

        ; Determinar en qué casilla se hizo click
        call coordenadas_a_casilla

        ; Verificar si el click fue dentro del tablero
        cmp casilla_actual, 255
        je fin_verificar

        ;==========================================================================================

        ; Verificar si la casilla está ocupada
        call verificar_casilla_libre
        cmp al, 0           ; AL = 0 si está libre, 1 si está ocupada
        jne fin_verificar

        ;==========================================================================================

        ; Marca logica de la casilla como ocupada por el jugador actual
        call marcar_casilla
        
        ;==========================================================================================

        ; Ocultar cursor del mouse
        mov ax, 0002h
        int 33h
    
        ; Dibujar X para Jugador 2
        push word ptr[casilla_actual]
        call dibujar_x_en_casilla  

        ;==========================================================================================

        ; Verificar si hay ganador / empate
        call verificar_tablero

        cmp msg_final, 0
        jne fin_verificar
        
        ;==========================================================================================

        ; Cambiar al siguiente jugador
        cambiar_turno:
            cmp jugador_actual, 1
            je cambiar_a_jugador2

            ; Cambiar a Jugador 1
            mov jugador_actual, 1
            jmp actualizar_turno

        cambiar_a_jugador2:
            mov jugador_actual, 2

        actualizar_turno:
            ; Actualizar display del turno
            call mostrar_turno_actual

            ; Mostrar cursor del mouse
            mov ax, 0001h
            int 33h
            call piece_sound

            jmp fin_verificar

        no_click:
            ; Si no hay click, resetear flag
            mov click_anterior, 0

        fin_verificar:
            call mostrar_mensaje_final

            ret
    verificar_mouse ENDP

    verificar_tablero proc
        push ax
        xor ax, ax

        push si
        xor si, si

        verificar_fila_1:
            ; Fila 1
            mov al, tablero_estado[1]
            cmp tablero_estado[0], al
            jne verificar_fila_2

            mov al, tablero_estado[2]
            cmp tablero_estado[0], al
            jne verificar_fila_2

            cmp al, 0
            je verificar_fila_2
 
        jmp verificar_ganador

        verificar_fila_2:
            ; Fila 2
            mov al, tablero_estado[4]
            cmp tablero_estado[3], al
            jne verificar_fila_3

            mov al, tablero_estado[5]
            cmp tablero_estado[3], al
            jne verificar_fila_3

            cmp al, 0
            je verificar_fila_3

        jmp verificar_ganador

        verificar_fila_3:
            ; Fila 3
            mov al, tablero_estado[7]
            cmp tablero_estado[6], al
            jne verificar_columna_1

            mov al, tablero_estado[8]
            cmp tablero_estado[6], al
            jne verificar_columna_1

            cmp al, 0
            je verificar_columna_1

        jmp verificar_ganador

        verificar_columna_1:
            ; Columna 1
            mov al, tablero_estado[3]
            cmp tablero_estado[0], al
            jne verificar_columna_2

            mov al, tablero_estado[6]
            cmp tablero_estado[0], al
            jne verificar_columna_2

            cmp al, 0
            je verificar_columna_2

        jmp verificar_ganador

        verificar_columna_2:
            ; Columna 2
            mov al, tablero_estado[4]
            cmp tablero_estado[1], al
            jne verificar_columna_3

            mov al, tablero_estado[7]
            cmp tablero_estado[1], al
            jne verificar_columna_3

            cmp al, 0
            je verificar_columna_3

        jmp verificar_ganador

        verificar_columna_3:
            ; Columna 3
            mov al, tablero_estado[5]
            cmp tablero_estado[2], al
            jne verificar_diagonal_1

            mov al, tablero_estado[8]
            cmp tablero_estado[2], al
            jne verificar_diagonal_1

            cmp al, 0
            je verificar_diagonal_1

        jmp verificar_ganador

        verificar_diagonal_1:
            ; Diagonal 1
            mov al, tablero_estado[4]
            cmp tablero_estado[0], al
            jne verificar_diagonal_2

            mov al, tablero_estado[8]
            cmp tablero_estado[0], al
            jne verificar_diagonal_2

            cmp al, 0
            je verificar_diagonal_2

        jmp verificar_ganador

        verificar_diagonal_2:
            ; Diagonal 2
            mov al, tablero_estado[4]
            cmp tablero_estado[2], al
            jne verificar_empate

            mov al, tablero_estado[6]
            cmp tablero_estado[2], al
            jne verificar_empate

            cmp al, 0
            je verificar_empate

        jmp verificar_ganador

        verificar_empate:
            ; Empate
            mov si, 0
        verificar_empate_loop:
            cmp tablero_estado[si],0
            je juego_continua

            cmp si, 8
            je termina_empate
            inc si
        jmp verificar_empate_loop


        verificar_ganador:
            cmp al, 1
            je gana_jugador_1

            mov msg_final,2
            
        jmp fin_verificar_tablero
        
        gana_jugador_1:
            mov msg_final, 1
            
        jmp fin_verificar_tablero
        
        termina_empate:
            mov msg_final, 3

        jmp fin_verificar_tablero

        juego_continua:
            mov msg_final, 0
        fin_verificar_tablero:
            pop si
            pop ax
            ret
    verificar_tablero endp

    verificar_casilla_libre PROC
        ;==========================================================================================
        ; Verifica si la casilla actualmente seleccionada está libre (sin jugada).
        ;
        ; Devuelve:
        ;   - AL = 1 → La casilla está libre.
        ;   - AL = 0 → La casilla ya está ocupada.
        ;
        ; Dependencias:
        ;   - tablero[] → Arreglo que representa el estado del tablero de juego.
        ;
        ; Notas:
        ;   - La función accede directamente al arreglo `tablero[casilla_actual]` y lo compara
        ;     con el valor 0 (libre).
        ;==========================================================================================

        
        push bx
        push si

        mov al, casilla_actual
        mov ah, 0
        mov si, ax

        ; Verificar el estado de la casilla en tablero_estado
        mov al, tablero_estado[si]
        cmp al, 0
        je casilla_libre

        ; Casilla ocupada
        mov al, 1
        jmp fin_verificar_libre

        casilla_libre:
            mov al, 0
        fin_verificar_libre:
            pop si
            pop bx
            ret
    verificar_casilla_libre ENDP

    coordenadas_a_casilla PROC
        ;==========================================================================================
        ; Convierte las coordenadas actuales del mouse en un número de casilla del tablero.
        ;
        ; Devuelve (in-place):
        ;   - casilla_actual = Número de casilla (0 a 8) si está dentro del tablero.
        ;   - casilla_actual = 255 si el puntero está fuera del área del tablero.
        ;
        ; Dependencias:
        ;   - mouse_x, mouse_y → Coordenadas actuales del puntero del mouse (ya corregidas).
        ;   - Constantes:
        ;       - TABLERO_X_INI, TABLERO_Y_INI → Coordenadas iniciales del tablero.
        ;       - TABLERO_ANCHO, TABLERO_ALTO → Dimensiones del tablero.
        ;       - CASILLA_SIZE → Tamaño de cada casilla.
        ;
        ; Notas:
        ;   - El tablero es de 3x3 casillas, cada una de 40x40 píxeles.
        ;       - 3 casillas horizontales: 100-140, 140-180, 180-220.
        ;       - 3 casillas verticales: 40-80, 80-120, 120-160
        ;   - Se verifica si el puntero está dentro del área útil del tablero.
        ;       - Si está dentro, se calcula la fila y columna correspondientes,
        ;         y se traduce a un índice lineal (casilla 0 a 8).
        ;==========================================================================================
        
        push ax
        push bx
        push cx
        push dx

        ; Verificar si está dentro del tablero

        ; X debe estar entre 100 y 219 (inclusive)
        cmp mouse_x, TABLERO_X_INI
        jb fuera_tablero
        mov ax, TABLERO_X_INI + TABLERO_ANCHO - 1          ; 100 + 120 - 1 = 219
        cmp mouse_x, ax
        ja fuera_tablero
        
        ; Y debe estar entre 40 y 159 (inclusive)
        cmp mouse_y, TABLERO_Y_INI
        jb fuera_tablero
        mov ax, TABLERO_Y_INI + TABLERO_ALTO - 1           ; 40 + 120 - 1 = 159
        cmp mouse_y, ax
        ja fuera_tablero
        
        ;==========================================================================================

        ; Calcular fila (0, 1, 2)
        mov ax, mouse_y
        sub ax, TABLERO_Y_INI
        mov bx, CASILLA_SIZE
        mov dx, 0
        div bx                                             ; AX = fila (0, 1, 2)
        
        ; Verificar que la fila esté en rango válido
        cmp ax, 2
        ja fuera_tablero
        
        mov bx, ax                                         ; Guardar fila en BX

        ;==========================================================================================
        
        ; Base de la fila
        mov ax, bx
        mov cx, 3
        mul cx                      
        mov bx, ax                                         ; BX = base de fila (0, 3, o 6)
        
        ;==========================================================================================

        ; Calcular columna (0, 1, 2)
        mov ax, mouse_x
        sub ax, TABLERO_X_INI
        mov cx, CASILLA_SIZE
        mov dx, 0
        div cx                                             ; AX = columna (0, 1, 2)
        
        ; Verificar que la columna esté en rango válido
        cmp ax, 2
        ja fuera_tablero
        
        ;==========================================================================================

        ; Base de fila + columna = casilla
        add bx, ax
        mov casilla_actual, bl
        jmp fin_coordenadas_a_casilla
        
        fuera_tablero:
            mov casilla_actual, 255
        fin_coordenadas_a_casilla:   
            pop dx
            pop cx
            pop bx
            pop ax

            ret
    coordenadas_a_casilla ENDP

    marcar_casilla PROC
        ;==========================================================================================
        ; Marca Logica de casilla actual ocupada por el jugador actual
        ;==========================================================================================
        push ax
        push bx
        push si
        
        mov al, casilla_actual
        mov ah, 0
        mov si, ax
        
        ; Marcar con el número del jugador actual
        mov al, jugador_actual
        mov tablero_estado[si], al
        
        pop si
        pop bx
        pop ax
        ret
    marcar_casilla ENDP

    ; ==================== PROCEDIMIENTOS DE DIBUJO ====================

    dibujar_linea_vertical PROC
        ;==========================================================================================
        ; Funcion para dibujar las lineas blancas verticales del tablero
        ; 
        ; Recibe (Por Stack):
        ;       [bp+8] = Valor de la coordenada X 
        ;       [bp+6] = Valor inicial de la coordenada Y
        ;       [bp+4] = Logitud de la linea
        ;
        ; Devuelve:
        ;   Ningun valor explicito. La linea es dibujada directamente en pantalla.
        ;
        ; Notas:
        ;   - Dibuja pixel por pixel incrementando Y.
        ;==========================================================================================
        push bp
        mov bp, sp

        push ax
        xor ax, ax
        push bx
        xor bx, bx
        push cx
        xor cx, cx
        push dx
        xor dx, dx
        push si
        xor si, si
        
        mov cx, ss:[bp+8]                       ; CX = X
        mov dx, ss:[bp+6]                       ; DX = Y inicial
        mov si, ss:[bp+4]                       ; SI = longitud

        mov al, 15                              ; Color blanco
        
        dibujar_v_loop:
            cmp si, 0
            je fin_v_linea
            
            ; Dibujar pixel en (CX, DX)
            mov ah, 0Ch
            mov bh, 0
            int 10h                             ; Print pixel
            
            inc dx                              ; Siguiente Y
            dec si                              ; Decrementar contador
            jmp dibujar_v_loop
            
        fin_v_linea:
            pop si
            pop dx
            pop cx
            pop bx
            pop ax

            pop bp
            ret 6
    dibujar_linea_vertical ENDP

    dibujar_linea_horizontal PROC
        ;==========================================================================================
        ; Funcion para dibujar las lineas blancas horizontales del tablero
        ; 
        ; Recibe (Por Stack):
        ;       [bp+8] = Valor inicial de la coordenada X 
        ;       [bp+6] = Valor de la coordenada Y
        ;       [bp+4] = Logitud de la linea
        ;
        ; Devuelve:
        ;   Ningun valor explicito. La linea es dibujada directamente en pantalla.
        ;
        ; Notas:
        ;   - Dibuja pixel por pixel incrementando X.
        ;==========================================================================================

        push bp
        mov bp, sp

        push ax
        xor ax, ax
        push bx
        xor bx, bx
        push cx
        xor cx, cx
        push dx
        xor dx, dx
        push si
        xor si, si
        
        mov cx, ss:[bp+8]                       ; CX = X inicial
        mov dx, ss:[bp+6]                       ; DX = Y
        mov si, ss:[bp+4]                       ; SI = longitud
        
        mov al, 15                              ; Color blanco
        
        dibujar_h_loop:
            cmp si, 0
            je fin_h_linea
            
            ; Dibujar pixel en (CX, DX)
            mov ah, 0Ch
            mov bh, 0
            int 10h                             ; Print pixel
            
            inc cx                              ; Siguiente X
            dec si                              ; Decrementar contador
            jmp dibujar_h_loop
            
        fin_h_linea:
            
            pop si
            pop dx
            pop cx
            pop bx
            pop ax

            pop bp
            ret 6
    dibujar_linea_horizontal ENDP

    dibujar_x_en_casilla PROC
        ;==========================================================================================
        ; Dibuja una "X" en una casilla especifica del tablero.
        ;
        ; Recibe (Por stack):
        ;       [bp+4] = Número de casilla (BYTE: valores de 0 a 8)
        ;
        ; Devuelve:
        ;   - Dibuja en pantalla una "X", ubicada en la casilla recibida por parametro.
        ;
        ; Dependencias:
        ;   - dibujar_diagonal_descendente
        ;   - dibujar_diagonal_ascendente
        ;   - Constantes:
        ;       - TABLERO_X_INI, TABLERO_Y_INI, CASILLA_SIZE
        ;
        ; Notas:
        ;   - La "X" se compone de 6 líneas diagonales (3 descendentes y 3 ascendentes) para dar grosor.
        ;   - Se aplica un margen de 8 píxeles para evitar que la figura toque los bordes.
        ;   - Si el número de casilla es mayor a 8, el procedimiento termina sin realizar dibujo.
        ;==========================================================================================

        push bp
        mov bp, sp

        push ax
        xor ax, ax
        push bx
        xor bx, bx
        push cx
        xor cx, cx
        push dx
        xor dx, dx

        push si
        xor si, si
        push di
        xor di, di
        

        mov ax, ss:[bp+4]

        ; Validar que la casilla esté en rango 0-8
        cmp al, 8
        ja fin_dibujar_x

        ;==========================================================================================        

        ; Convertir número de casilla a coordenadas de esquina superior izquierda

        mov ah, 0
        
        ; fila = casilla / 3
        mov bl, 3
        div bl                              
        mov bl, al                          ; BL = fila
        mov cl, ah                          ; CL = columna
        
        ;==========================================================================================

        ; Calcular coordenada Y de la esquina superior izquierda de la casilla

        ; Y = TABLERO_Y_INI + (fila * CASILLA_SIZE)
        mov al, bl
        mov ah, 0
        mov dx, CASILLA_SIZE
        mul dx                              ; AX = fila * CASILLA_SIZE
        add ax, TABLERO_Y_INI
        mov si, ax                          ; SI = Y inicial de la casilla

        ;==========================================================================================        

        ; Calcular coordenada X de la esquina superior izquierda de la casilla

        ; X = TABLERO_X_INI + (columna * CASILLA_SIZE)
        mov al, cl
        mov ah, 0
        mov dx, CASILLA_SIZE
        mul dx                              ; AX = columna * CASILLA_SIZE
        add ax, TABLERO_X_INI
        mov di, ax                          ; DI = X inicial de la casilla
        
        ;==========================================================================================

        ; Margen de 8 píxeles
        add di, 8
        add si, 8
        
        ; Calcular tamaño de la X (CASILLA_SIZE - 16 para margenes)
        mov bx, CASILLA_SIZE - 16
        
        ;==========================================================================================

        ; DIAGONAL 1

        ; Dibujar principal (\)
        mov cx, di                          ; X inicial
        mov dx, si                          ; Y inicial
        call dibujar_diagonal_descendente
        
        ; Dibujar desplazada 1 pixel a la derecha
        mov cx, di
        inc cx
        mov dx, si
        call dibujar_diagonal_descendente
        
        ; Dibujar desplazada 1 pixel hacia abajo
        mov cx, di
        mov dx, si
        inc dx
        call dibujar_diagonal_descendente
        
        ;==========================================================================================

        ; DIAGONAL 2

        ; Dibujar principal (/)
        mov cx, di
        add cx, bx                          ; X final
        dec cx
        mov dx, si                          ; Y inicial
        call dibujar_diagonal_ascendente
        
        ; Dibujar desplazada 1 pixel a la izquierda
        mov cx, di
        add cx, bx
        sub cx, 2                           ; X final - 1
        mov dx, si
        call dibujar_diagonal_ascendente
        
        ; Dibujar desplazada 1 pixel hacia abajo
        mov cx, di
        add cx, bx
        dec cx
        mov dx, si
        inc dx
        call dibujar_diagonal_ascendente

        fin_dibujar_x:
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            pop bp
            ret 2
    dibujar_x_en_casilla ENDP

    dibujar_diagonal_descendente PROC
        ;==========================================================================================
        ; Dibuja una línea diagonal descendente (\) desde una posición inicial.
        ;
        ; Entrada (por registros):
        ;   - CX = Coordenada X inicial.
        ;   - DX = Coordenada Y inicial.
        ;
        ; Dependencias:
        ;   - CASILLA_SIZE → Tamaño de una casilla (para determinar longitud de la línea).
        ;
        ; Notas:
        ;   - Esta función no realiza validaciones de coordenadas de límite de pantalla.
        ;==========================================================================================
        
        push ax
        push bx
        push cx
        push dx
        
        mov ax, bx                                      ; AX = contador
        
        desc_loop:
            cmp ax, 0
            je fin_desc
            
            ; Dibujar pixel en (CX, DX)
            push ax
            
            cmp jugador_actual, 1
            jne player_2_color_diagonal_descendente
            
            mov al, 12                                  ; Color Rojo
            jmp player_1_color_diagonal_descendente

            player_2_color_diagonal_descendente:
                mov al, 9                               ; Color Azul
            
            player_1_color_diagonal_descendente:
            mov ah, 0Ch
            mov bh, 0
            int 10h                                     ; Print pixel
            pop ax
            
            inc cx                                      ; Siguiente X
            inc dx                                      ; Siguiente Y
            dec ax                                      ; Decrementar contador
        jmp desc_loop
            
        fin_desc:
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    dibujar_diagonal_descendente ENDP

    dibujar_diagonal_ascendente PROC
        ;==========================================================================================
        ; Dibuja una línea diagonal ascendente (/) desde una posición inicial.
        ;
        ; Entrada (por registros):
        ;   - CX = Coordenada X inicial.
        ;   - DX = Coordenada Y inicial.
        ;
        ; Dependencias:
        ;   - CASILLA_SIZE → Tamaño de una casilla (para determinar longitud de la línea).
        ;
        ; Notas:
        ;   - Esta función no realiza validaciones de coordenadas de límite de pantalla..
        ;==========================================================================================
        
        push ax
        push bx
        push cx
        push dx
        
        mov ax, bx                                      ; AX = contador
        
        asc_loop:
            cmp ax, 0
            je fin_asc
            
            ; Dibujar pixel en (CX, DX)
            push ax

            cmp jugador_actual, 1
            jne player_2_color_diagonal_ascendente

            mov al, 12                                  ; Color Rojo
            jmp player_1_color_diagonal_ascendente

            player_2_color_diagonal_ascendente:
                mov al, 9                               ; Color Azul
            player_1_color_diagonal_ascendente:

            mov ah, 0Ch
            mov bh, 0
            int 10h                                     ; Print pixel
            pop ax
            
            dec cx                                      ; X anterior
            inc dx                                      ; Siguiente Y
            dec ax                                      ; Decrementar contador
            jmp asc_loop
            
        fin_asc:
            pop dx
            pop cx
            pop bx
            pop ax
            ret
    dibujar_diagonal_ascendente ENDP

    ; ==================== PROCEDIMIENTOS DE SONIDOS ====================

    piece_sound proc
        ;==========================================================================================
        ; Sonido cuando se coloca una pieza
        ;==========================================================================================
        mov ah, 01h                 ; Función 01h = sonido de pieza colocada
        int 80h                     ; Llamar al sistema de sonidos
        ret
    piece_sound endp

    draw_sound proc
        ;==========================================================================================
        ; Reproduce la secuencia completa de empate
        ;==========================================================================================
        
        ; Parte 1 del empate (Mi5)
        mov ah, 02h
        int 80h

        call short_pause

        ; Parte 2 del empate (Do5)
        mov ah, 03h
        int 80h

        call short_pause

        ; Parte 3 del empate (La4)
        mov ah, 04h
        int 80h

        ret
    draw_sound endp

    
    victory_sound proc
        ;==========================================================================================
        ; Reproduce la secuencia completa de victoria
        ;==========================================================================================

        ; Parte 1 de victoria (Do5)
        mov ah, 05h
        int 80h

        call short_pause

        ; Parte 2 de victoria (Mi5)
        mov ah, 06h
        int 80h

        call short_pause

        ; Parte 3 de victoria (Sol5)
        mov ah, 07h
        int 80h

        ret
    victory_sound endp

    short_pause proc

        push cx
        push dx
        mov cx, 0002h               ; Parte alta de microsegundos
        mov dx, 49F0h               ; 200,000 microsegundos = 200ms
        mov ah, 86h
        int 15h
        pop dx
        pop cx
        ret
    short_pause endp

    end