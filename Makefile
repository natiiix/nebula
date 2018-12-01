boot.bin: *.asm
	nasm boot.asm -f bin -o boot.bin

clean:
	rm boot.bin
