; =======================================================================================
; PROYECTO FINAL ASSEMBLER - TATETI
; =======================================================================================
;
; Descripción:
; -------------
;   Juego clásico de Ta-Te-Ti para dos jugadores, implementado en assembler
;   utilizando modo gráfico VGA (320x200, 256 colores). El usuario interactúa
;   con el mouse, seleccionando casillas para colocar su jugada.
;
; Funcionalidades:
; -----------------
;   - Dibujo del tablero e interfaz gráfica.
;   - Manejo del mouse (int 33h) para clics y coordenadas.
;   - Detección de jugadas válidas y control de turnos.
;   - Verificación automática de victoria o empate.
;   - Mensajes e instrucciones en pantalla.
;   - Sistema de sonidos por interrupcion personalizada.
;
; Archivos:
; ----------
;   - tateti.asm       → Control general del juego.
;   - Ltateti.asm      → Funciones gráficas y de lógica auxiliar.
;   - soundi.asm       → Interrupcion personalizada para sonidos.
;
; Dependencias:
; --------------
;   - DOSBox
;   - TASM + TLINK
;
;   Desarrollado por Tomás Mesa, Roman Fabris
;   Materia: Sistema de procesamiento de datos | Año: 2025 1C
; =======================================================================================

.MODEL SMALL
.STACK 100h

.DATA
    
.CODE
    extrn inicializar_variables:proc
    extrn inicializar_grafico:proc
    extrn inicializar_mouse:proc
    extrn dibujar_tablero:proc
    extrn mostrar_instrucciones:proc
    extrn mostrar_turno_actual:proc
    extrn verificar_mouse:proc

    main proc
        mov ax, @data
        mov ds, ax

        ; Inicializar modo gráfico VGA 320x200x256
        call inicializar_grafico
        
    reiniciar_Juego:
    
        ; Setear variables con valores iniciales
        call inicializar_variables 
        
        ; Inicializar mouse
        call inicializar_mouse
            
        ; Dibujar el tablero
        call dibujar_tablero
        
        ; Mostrar instrucciones
        call mostrar_instrucciones
        
        ; Mostrar turno inicial
        call mostrar_turno_actual
        
        ; Bucle principal
    bucle_principal:
        ; Verificar estado del mouse
        call verificar_mouse

    juego_continua:
        ; Verificar si se presionó ESC
        mov ah, 01h         ; Verificar si hay tecla presionada
        int 16h
        jz bucle_principal  ; Si no hay tecla, continuar
        
        mov ah, 00h         ; Leer tecla
        int 16h
        
        cmp al, 1bh         ; Comparar con ESC
        je salir

        cmp al, 0dh
        je reiniciar_Juego

        jmp bucle_principal

    salir:
        ; Restaurar modo texto
        mov ax, 0003h
        int 10h
        
        ; Terminar programa
        mov ax, 4C00h
        int 21h

    main endp

END MAIN