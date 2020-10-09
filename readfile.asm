%include "linux64.inc.asm"

section .data
    filename db "0/test.txt", 0
    space db " ", 0
    spacelen equ $-space

%macro syswrite 1
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, %1
    mov rdx, 2
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
%endmacro

section .bss
    exp  resb 5         ; Exponente a la que elevar la base
    mod  resb 5         ; Modulo de la base
    char resb 1         ; Espacio de memoria para el caracter leido

section .text
    global _start

_start:
    ; Lectura de los argumentos del programa
    pop rax             ; Numero de argumentos ingresados

    pop rax             ; Path al ejecutable

    pop rdx             ; Exponente (d)
    call _string2int    ; Se convierte a un numero
    mov rcx, rax        ; Se guarda exponente en RCX
    
    pop rdx             ; Modulo (n)
    call _string2int    ; Se convierte a un numero
    push rax            ; Se guarda el exponente en el stack
    push rcx            ; Se guarda el modulo en el stack

    ; Apertura del archivo de la imagen en modo lectura 
    mov rax, SYS_OPEN   ; Numero de llamada al sistema 'open'
    mov rdi, filename   ; Ruta del archivo
    mov rsi, O_RDONLY   ; Modo de solo lectura
    mov rdx, 0          
    syscall

    mov r8, rax         ; Se almacena el file descriptor en R8


_readChar:
    mov r9, 0           ; R9 = contador de digitos
    mov r10, 0          ; R10 = contador de numeros
    push r9             ; Se guarda un 0 en el stack 
_readCharLoop:
    ; Lectura del archivo
    mov rdi, r8
    mov rax, SYS_READ
    mov rsi, char
    mov rdx, 1
    syscall

    ; Se compara el caracter leido con un ' '
    mov esi, char       ; Primer operando
    mov edi, space      ; Segundo operando
    mov ecx, spacelen   ; Cantidad de bytes a comparar
    rep cmpsb           ; Comparacion de esi y edi
    je  _saveNumber

    ; Se convierte el texto a un numero
    mov rdx, char       ; Registro donde se almacena el argumento
    call _string2int   
    ; RAX contiene el numero obtenido del string

    ; Se construye el numero
    mov r9, rax         ; Se copia el numero leido
    pop rax             ; Se obtiene el numero construido hasta el momento
    mov rdi, 10
    mul rdi             ; Se multiplica por 10 el numero construido hasta el momento
    add r9, rax         ; Se suma el numero leido
    push r9             ; Se guarda el numero construido hasta el momento
    jmp _readCharLoop
_saveNumber:
    inc r10             ; Incrementar contador de numeros
    cmp r10, 2          ; Contador numeros == 2 ?
    je _decodeNumber    ; Se decodifican los dos bytes leidos

    push 0              ; Se reinicia el numero construido
    jmp _readCharLoop       ; Se construye el siguiente numero

_decodeNumber:
    ; Se construye el byte codificado con el MSB y LSB leidos, se guarda en RAX
    pop rdi             ; Se obtiene el LSB del numero codificado
    pop rax             ; Se obtiene el MSB del numero codificado
    shl rax, 8          ; Se mueve el MSB 8 posiciones a la izquierda
    or rax, rdi         ; Se realiza un OR para copiar el LSB 

    pop rsi             ; Se obtiene el exponente
    pop rdi             ; Se obtiene el modulo
    push rsi            ; Se guarda de nuevo en el stack
    push rdi            ; Se guarda de nuevo en el stack

    ;-------------------------------------------------------------------------

    ; Verificar si numero se encuentra dentro de la tabla

    ;-------------------------------------------------------------------------

    ; Se calcula el modulo de la base para evitar calculos con numeros grandes
    cmp rax, rdi        ; Se ejecuta solo si la base es mayor al modulo
    jg _modBase
    
_continueDecodeNumber: 
    ; Se preparan los parametros para aplicar la exponenciacion modular
    mov r9, 1           ; Valor inicial de la exponenciacion
    mov rcx, 1          ; Se utiliza para construir el resultado final
    mov r10, 1          ; Valor para enmascarar los bits del exponente
    jmp _modExp

_modBase:
    ; Funcion para aplicar el modulo a la base para reducir su magnitud,
    ; se ejecuta solo si la base es diferente del modulo
    mov rdx, 0
    div rdi             ; Se divide la base por el modulo
    mov rax, rdx        ; Se obtiene el resultado del modulo
    jmp _continueDecodeNumber


_modExp:
    ; RDX se utiliza para calcular el resultado del modulo, pero se guarda en RAX
    ; RSI almacena el exponente de la llave privada
    ; RDI almacena el modulo de la llave privada
    ; RCX se utiliza para construir el resultado total de la exponenciacion modular
    ; R9 almacena el exponente de la iteracion, se usa para verificar si es mayor a RSI
    ; R10 se utiliza para enmascarar los bits del exponente de la llave privada
    ; R11 se utiliza manipular el exponente de la llave sin perder el valor original
    ; R9, RCX y R10 deben iniciar en 1 para la primera iteracion

    ; Verificacion de la condicion de parada
    ; Exponente actual supera al exponente utilizado para codificar
    cmp r9, rsi         ; Condicion de parada
    jg _endModExp       ; Termina si r9 > rsi

    ; Calculo del modulo
    mov rdx, 0
    div rdi
    mov rax, rdx        ; Se almacena el modulo de la operacion en RAX

    ; Enmascarar bit actual del exponente de la llave para conocer si resultado debe utilizarse
    mov r11, rsi        ; Copia valor del exponente para manipular sin perder el original 
    and r11, r10        ; Enmacarar bit actual
    cmp r11, r10        ; Resultado debe utilizarse ?
    je _addExp          ; Se agrega el resultado obtenido al resultado total

_continueModExp:
    shl r10, 1          ; Se mueve un valor a la izquierda el numero para enmascarar bits
    mul rax             ; RAX = RAX * RAX    Calculo de la siguiente exponenciacion
    push rax            ; Se almacena el valor del modulo calculado para hacer una multiplicacion
    mov rdx, 2          ; Se debe multiplicar exponente por 2
    mov rax, r9         ; Se mueve exponente a RAX para multiplicar
    mul rdx             ; RAX = RAX * 2, se multiplica exponente por 2
    mov r9, rax         ; Se guarda el nuevo resultado en el registro R9
    pop rax             ; Se restaura el valor del modulo calculado
    jmp _modExp         ; Loop


_addExp:
    ; Funcion para sumar un resultado de la exponenciacion modular al resultado final
    push rax            ; Almacena en stack el resultado del modulo
    mul rcx             ; Multiplicacion iteraciones anteriores con el resultado obtenido
    mov rdx, 0
    div rdi             ; Se calcula nuevamente el modulo para disminuir la magnitud del numero
    mov rcx, rdx        ; Almacenar multiplicacion en RCX
    pop rax             ; Se recupera el resultado del modulo
    jmp _continueModExp

_endModExp:
    printVal rcx
    jmp _exit

_exit: 
    ; Cierre del archivo
    mov rax, SYS_CLOSE
    mov rdi, R8
    syscall
    
    ;pop rax
    ;printVal r12
    ;pop rax
    ;printVal rax

    exit



_string2int:    
    ; RDX tiene el string del numero
    ; RAX contiene el resultado
    push rcx
    atoi:
    xor rax, rax            ; zero a "result so far"
    .top:
    movzx rcx, byte [rdx]   ; get a character
    inc rdx                 ; ready for next one
    cmp rcx, '0'            ; valid?
    jb .done
    cmp rcx, '9'
    ja .done
    sub rcx, '0'            ; "convert" character to number
    imul rax, 10            ; multiply "result so far" by ten
    add rax, rcx            ; add in current digit
    jmp .top                ; until done
    .done:
    pop rcx
    ret