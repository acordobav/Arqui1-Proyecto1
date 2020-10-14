readfile : decoder.asm
	nasm -f elf64 -o decoder.o decoder.asm
	ld decoder.o -o decoder

clean :
	rm decoder decoder.o decodedimage.txt