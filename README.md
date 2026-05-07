# Tic-Tac-Toe in Assembly (TASM)

Juego clásico de Ta-Te-Ti para dos jugadores implementado en x86 Assembly utilizando modo gráfico VGA (320x200, 256 colores).

El proyecto utiliza interrupciones para manejo gráfico, control del mouse y reproducción de sonido dentro de un entorno DOS.

## Funcionalidades

- Interfaz gráfica en modo VGA
- Manejo de mouse mediante `int 33h`
- Detección de jugadas válidas
- Control automático de turnos
- Verificación de victoria o empate
- Mensajes e instrucciones en pantalla
- Sistema de sonido mediante interrupción personalizada

## Estructura del Proyecto

- `tateti.asm` → Control principal del juego
- `Ltateti.asm` → Funciones gráficas y lógica auxiliar
- `soundi.asm` → Interrupción personalizada para sonidos
- `compile.bat` → Script de compilación y ejecución

## Requisitos

- DOSBox
- TASM
- TLINK

## Compilación y Ejecución

El proyecto incluye un script `.bat` para automatizar la compilación y ejecución.

### Pasos

1. Abrir DOSBox.
2. Montar la carpeta del proyecto.
3. Ejecutar: `compile.bat`

> El script:
> - Compila el módulo de sonido,
> - Genera la interrupción personalizada,
> - Compila los módulos principales,
> - Enlaza el ejecutable final,
> - Ejecuta el juego automáticamente.

## Integrantes
* **Tomás Mesa** - UNSAM
* **Roman Fabris** - UNSAM

**Materia:** Sistema de Procesamiento de Datos  
**Profesores:** Fabio Bruschetti | Pedro Iriso