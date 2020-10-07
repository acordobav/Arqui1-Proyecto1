%include "linux64.inc.asm"

section .data
    filename db "0/test.txt", 0
    space db " ", 0
    spacelen equ $-space
    true db "true", 10, 0
    false db "false", 10, 0
    number db "110", 0
    number1 db "1", 0
    number2 db "2", 0
    number3 db "3", 0

section .bss
    text resb 2

section .text
    global _start

_start:
    ; Apertura del archivo en modo lectura 
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    ; Lectura del archivo
    mov r8, rax
    mov r9, 0       ; R9 = contador de digitos
    mov r10, 0      ; R10 = contador de numeros
_readChar:
    mov rdi, r8
    mov rax, SYS_READ
    mov rsi, text
    mov rdx, 1
    syscall

    ; Se compara el caracter leido con un ' '
    mov esi, text       ; Primer operando
    mov edi, space      ; Segundo operando
    mov ecx, spacelen   ; Cantidad de bytes a comparar
    rep cmpsb           ; Comparacion de esi y edi

    je _true
    jmp _false

_true: 
    inc r10             ; Incrementar contador de numeros
    call _buildNumber   ; Se reconstruye el numero
    mov r9, 0           ; Reiniciar contador de digitos
    cmp r10, 2          ; Contador de numeros == 2 ?
    je _buildEncriptedNumber
    jmp _readChar

_false:
    push text       ; Almacenar caracter en el stack
    inc r9          ; Aumento contador de digitos
    jmp _readChar   ; Leer siguiente caracter

_buildNumber:
    ; En R11 se construye el numero
    ; Resultado se guarda en la pila
    ; R9 es el contador de digitos
    ; RBX se utiliza para multiplicar por 10 el digito
    pop rax
    mov rbp, rax
    mov r11, 0
    mov rbx, 1
    mov rsi, 10

    pop r14
    push r14
    printVal r14

_buildNumberLoop:
    pop rdx             ; Obtener caracter almacenado
    call _string2int    ; Se convierte el caracter a un numero
    mul rbx             ; Se multiplica el numero por un factor de 10
    add r11, rax        ; Numero se construye en R11 
    dec r9              ; Contador digitos -= 1
    
    mov rax, rbx
    mul rsi             ; Aumenta en 10 el valor de RBX
    mov rbx, rax

    cmp r9, 0           ; Contador digitos == 1 ?
    je _saveNumber      ; Almacenar numero obtenido
    jmp _buildNumberLoop

_saveNumber:
    push r11        ; Almacenar numero en la pila
    push rbp
    ret

_string2int:    
    ;mov edx = string ; edx tiene el string del numero
    ; rax contiene el resultado
    atoi:
    xor eax, eax ; zero a "result so far"
    .top:
    movzx ecx, byte [edx] ; get a character
    inc edx ; ready for next one
    cmp ecx, '0' ; valid?
    jb .done
    cmp ecx, '9'
    ja .done
    sub ecx, '0' ; "convert" character to number
    imul eax, 10 ; multiply "result so far" by ten
    add eax, ecx ; add in current digit
    jmp .top ; until done
    .done:
    ret

_buildEncriptedNumber:
    ; Cierre del archivo
    mov rax, SYS_CLOSE
    pop rdi
    syscall
    
    ;pop rax
    ;printVal rax
    ;pop rax
    ;printVal rax

    exit