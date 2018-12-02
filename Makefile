boot.bin: *.asm
	nasm -w+all boot.asm -f bin -o boot.bin

clean:
	rm boot.bin

disassemble:
	objdump -b binary -Mintel -mi386 -Maddr16,data16 -D boot.bin
