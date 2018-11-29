boot.bin: boot.asm
	nasm boot.asm -f bin -o boot.bin

clean:
	rm boot.bin

run: boot.bin
	@echo "Note: To quit QEMU press Ctrl+A X"
	@qemu-system-i386 -nographic -drive file=boot.bin,format=raw

