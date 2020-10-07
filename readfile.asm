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
    text resb 1

section .text
    global _start

_start:
    ; Apertura del archivo en modo lectura 
    mov rax, SYS_OPEN   ; Numero de llamada al sistema 'open'
    mov rdi, filename   ; Ruta del archivo
    mov rsi, O_RDONLY   ; Modo de solo lectura
    mov rdx, 0          
    syscall

    mov r8, rax         ; Se almacena el file descriptor en R8
    mov r9, 0           ; R9 = contador de digitos
    mov r10, 0          ; R10 = contador de numeros
    push r9             ; Se guarda un 0 en el stack 
_readChar:
    ; Lectura del archivo
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
    je  _saveNumber

    ; Se convierte el texto a un numero
    mov edx, text       ; Registro donde se almacena el argumento
    call _string2int   
    ; RAX contiene el numero obtenido del string

    ; Se construye el numero
    mov r9, rax         ; Se copia el numero leido
    pop rax             ; Se obtiene el numero construido hasta el momento
    mov rdi, 10
    mul rdi             ; Se multiplica por 10 el numero construido hasta el momento
    add r9, rax         ; Se suma el numero leido
    push r9             ; Se guarda el numero construido hasta el momento
    jmp _readChar
_saveNumber:
    inc r10             ; Incrementar contador de numeros
    cmp r10, 2          ; Contador numeros == 2 ?
    je _buildEncriptedNumber

    push 0              ; Se reinicia el numero construido
    jmp _readChar       ; Se construye el siguiente numero

_buildEncriptedNumber:
    ; Cierre del archivo
    mov rax, SYS_CLOSE
    mov rdi, R8
    syscall
    
    pop rdi
    printVal rdi
    pop rax
    shl rax, 8
    or rax, rdi 
    printVal rax
    exit

    ;pop rax
    ;printVal r12
    ;pop rax
    ;printVal rax

    exit



_string2int:    
    push rcx

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

    pop rcx
    ret