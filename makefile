readfile : readfile.asm
	nasm -f elf64 -o readfile.o readfile.asm
	ld readfile.o -o readfile

