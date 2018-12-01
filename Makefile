boot.bin: *.asm
	nasm -w+all boot.asm -f bin -o boot.bin

clean:
	rm boot.bin
