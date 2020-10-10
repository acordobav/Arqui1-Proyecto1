%include "linux64.inc.asm"

section .data
    ;filename db "0/test.txt", 0
    fileNotFound db "Archivo no encontrado, por favor verifique la ruta", 10, 0
    fnfLen equ $-fileNotFound
    argsError db "Cantidad de argumentos no es la correcta, por favor ingrese: ruta, exponente y modulo", 10, 0
    argsErrorLen equ $-argsError
    space db " ", 0
    spacelen equ $-space
    decodedImage db "decodedimage.txt", 0
    ;table db 0

%macro syswrite 3
    ; %1 = File Descriptor
    ; %2 = String a escribir (buffer)
    ; %3 = Cantidad de bytes a escribir
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, SYS_WRITE
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
%endmacro

%macro sysopen 3
    ; %1 = Ruta del archivo
    ; %2 = Modo de apertura
    push rdi
    push rsi
    push rdx

    mov rax, SYS_OPEN   ; Numero de llamada al sistema 'open'
    mov rdi, %1         ; Ruta del archivo
    mov rsi, %2         ; Modo de apertura
    mov rdx, %3          
    syscall

    pop rdx
    pop rsi
    pop rdi
%endmacro

%macro sysclose 1
    ; %1 = File descriptor
    push rax
    push rdi

    mov rax, SYS_CLOSE
    mov rdi, %1
    syscall

    pop rdi
    pop rax
%endmacro

section .bss
    char resb 1         ; Espacio de memoria para el caracter
    table resb 771     ; Espacio de memoria para la tabla
    
section .text
    global _start

_start:
    ;mov rdx, table


    ;mov rbx, 31000
    ;mov [rdx], bx

    ;mov rbx, 100
    ;add rdx, 2
    ;mov [rdx], bl
    ;-----------------


    ;mov rbx, 32000
    ;add rdx, 1
    ;mov [rdx], bx

    ;mov rbx, 200
    ;add rdx, 2
    ;mov [rdx], bl
    ;-----------------


    ;mov rbx, 33000
    ;add rdx, 1
    ;mov [rdx], bx

    ;mov rbx, 182
    ;add rdx, 2
    ;mov [rdx], bl
    ;-----------------


    ;mov rbx, 34000
    ;add rdx, 1
    ;mov [rdx], bx

    ;mov rbx, 77
    ;add rdx, 2
    ;mov [rdx], bl
    ;-----------------


    ;mov rbx, 1585
    ;add rdx, 1
    ;mov [rdx], bx

    ;mov rbx, 182
    ;add rdx, 2
    ;mov [rdx], bl
    ;-----------------


    ;mov rcx, 5
    ;mov rdx, table
    ;add rdx, rcx
    ;mov bx, [rdx]
    ;and bx, 255
    ;printVal rbx
    ;exit

    ;mov rax, 1585
    ;call _verifyOnTable
    ;printVal rcx
    ;exit




    ; Lectura de los argumentos del programa
    ; Verificacion cantidad de argumentos debe ser 4
    pop rax             ; Numero de argumentos ingresados
    cmp rax, 4          ; Cantidad esperada
    jne _argsError

    pop rax             ; Path al ejecutable

    ; Apertura del archivo de la imagen en modo lectura 
    pop rdi             ; Ruta del archivo
    sysopen rdi, O_RDONLY, 0
    mov r8, rax         ; Se almacena el file descriptor en R8
    cmp rax, 0          ; Verificacion si la apertura del archivo fue correcta
    jl _fileNotFound

    ; Se abre el archivo de la imagen desencriptada
    sysopen decodedImage, O_CREAT+O_WRONLY+O_TRUNC, 0644o
    mov rsi, rax        ; Se mueve a RSI el file descriptor de la nueva imagen

    pop rdx             ; Argumento con el exponente (d) 
    call _string2int    ; Se convierte a un numero
    mov rcx, rax        ; Se guarda exponente en RCX
    
    pop rdx             ; Argumento con el modulo (n)
    call _string2int    ; Se convierte a un numero
    push rsi            ; Se guarda el file descriptor del archivo de la nueva imagen
    push rax            ; Se guarda el exponente en el stack
    push rcx            ; Se guarda el modulo en el stack
    
    jmp _readChar

_fileNotFound:
    syswrite 1, fileNotFound, fnfLen
    exit

_argsError: 
    syswrite 1, argsError, argsErrorLen
    exit

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

    cmp rax, 0          ; Se verifica si los bytes leidos son cero
    je _exit            ; Se termina el programa

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
    pop r12             ; Se obtiene el file descriptor de la nueva imagen
    push r12            ; Se guarda de nuevo en el stack
    push rdi            ; Se guarda de nuevo en el stack
    push rsi            ; Se guarda de nuevo en el stack

    ;-------------------------------------------------------------------------

    ; Verificar si numero se encuentra dentro de la tabla
    call _verifyOnTable ; RAX = numero; RCX = resultado busqueda
    cmp rcx, 0          ; 0 no encontrado, cotiene el numero en caso contrario
    jne _writeNumber    ; Se escribe numero en el archivo
    push rax            ; Se almacena numero codificado para ser almacenado en la tabla

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
    jg _updateTable     ; Termina si r9 > rsi

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

_updateTable:
    ; Funcion para actualizar la tabla de decodificaciones
    ; Numero debe estar en RCX
    pop rax             ; Se obtiene numero decodificado
    push rbx
    push rsi
    mov rbx, table      ; RBX contiene el puntero a la tabla

_updateTableLoop:
    ; Funcion para encontrar la primera posicion vacia en la tabla de decodificaciones
    mov si, [rbx]
    cmp rsi, 0              ; Condicion de parada: se ha encontrado un espacio vacio
    je _endUpdateTable
    add rbx, 3              ; Aumentar direccion de memoria para leer siguiente valor
    jmp _updateTableLoop
_endUpdateTable:
    mov [rbx], ax           ; Se almacena numero codificado en la tabla
    add rbx, 2  
    mov [rbx], cl           ; Se almacena numero decodificado en la tabla
    pop rsi
    pop rbx
    jmp _writeNumber

_writeNumber:
    ; Numero debe estar en RCX
    ; RDI sera el contador de digitos
    mov rsi, 10
    mov rax, rcx
    mov rdi, 0
    jmp _int2string

_int2string:
    mov rdx, 0
    div rsi         ; Se calcula numero menos significativo
    inc rdi         ; Incrementar contador de digitos
    add rdx, 48     ; Se convierte a ASCII
    push rdx        ; Almacenar numero menos significativo
    cmp rax, 0      ; Condicion de parada: no queda residuo 
    je _writeNumberLoop
    jmp _int2string

_writeNumberLoop:
    cmp rdi, 0              ; Condicion de parada, todos los digitos escritos
    je _endWriting          ; Se lee siguiente numero encriptado

    mov rcx, char           ; Se obtiene direccion de memoria del caracter
    pop rax                 ; Se obtiene numero
    mov [rcx], al           ; Se guarda numero en memoria
    syswrite r12, char, 1   ; Escritura en el archivo imagen decodificada
    dec rdi                 ; Disminuir contador de digitos
    jmp _writeNumberLoop

_endWriting:
    mov rcx, char
    mov rax, 32
    mov [rcx], rax
    syswrite r12, char, 1   ; Escritura de un espacio en el archivo imagen decodificada 
    jmp _readChar

_verifyOnTable:
    ; (Argumento) RAX: contiene el numero a verificar
    ; (Resultado) RCX: 1 si se ha calculado el numero, 0 en caso contrario
    
    ; RBX: registro con puntero a la tabla
    ; RSI: registro para cargar valor de la tabla
    push rbx
    push rsi
    mov rbx, table      ; RBX contiene el puntero a la tabla
    mov rcx, 0          ; Valor de retorno por defecto
    jmp _verifyOnTableLoop

_verifyOnTableLoop:
    mov si, [rbx]

    cmp rsi, 0              ; Condicion de parada: se ha leido toda la tabla, no se encontro el valor
    je _endVerifyTable

    add rbx, 3              ; Aumentar direccion de memoria para leer siguiente valor
    cmp rsi, rax            ; Verifica si valor de la tabla es el valor que se decodifica
    jne _verifyOnTableLoop  ; Loop: leer siguiente valor en caso de que no sean iguales
    sub rbx, 1              ; Se indexa al valor decodificado en la tabla
    mov sil, [rbx]          ; Se obtiene valor decodificado
    and rsi, 255            ; Se almacenan solo los 8 bits menos significativos
    mov rcx, rsi            ; Valor decodificado se almacena en rcx
    jmp _endVerifyTable

_endVerifyTable:
    ; Se restauran los registros
    pop rsi
    pop rbx
    ret

_exit: 
    ; Cierre del archivo codificado
    sysclose R8     ; Cerrar archivo imagen codificada
    sysclose R12    ; Cerrar archivo imagen decodificada
    exit            ; Fin de la ejecucion del programa

    mov rbx, table      ; RBX contiene el puntero a la tabla
    mov rax, 0
    jmp _printTable

_printTable:
    printVal rbx
    mov rsi, 0
    mov si, [rbx]           
    cmp si, 0              ; Condicion de parada: se ha leido toda la tabla, no se encontro el valor
    je _endPrintTable

    cmp rax, 256            ; Condicion de parada: se ha leido toda la tabla, no se encontro el valor
    je _endPrintTable


    add rbx, 2              ; Aumentar direccion de memoria para leer siguiente valor
    mov sil, [rbx]          ; Se obtiene valor decodificado
    and rsi, 255            ; Se almacenan solo los 8 bits menos significativos    
    ;printVal rsi
    inc rbx              ; Aumentar direccion de memoria para leer siguiente valor
    inc rax
    jmp _printTable

_endPrintTable:
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