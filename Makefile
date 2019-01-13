SRC=src/
MAIN=$(SRC)main.asm
BIN=bin/nebula.bin
STABLE=bin/stable.bin

$(BIN): $(shell find $(SRC) -name "*.asm")
	nasm -w+all -f bin -i $(SRC) -o $(BIN) $(MAIN)
	cp ${BIN} ${STABLE}

clean:
	rm $(BIN)

disassemble: $(BIN)
	objdump -b binary -Mintel -mi386 -Maddr16,data16 -D $(BIN)

hex: $(BIN)
	xxd $(BIN) | less
