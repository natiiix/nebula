SRC_DIR=src/
MAIN=${SRC_DIR}main.asm
BIN_DIR=bin/
BIN_FILE=${BIN_DIR}nebula.bin
STABLE_BIN_FILE=${BIN_DIR}stable.bin
FLOPPY_FILE=${BIN_DIR}floppy.img

.PHONY: build
build: ${STABLE_BIN_FILE}

${STABLE_BIN_FILE}: Makefile $(wildcard $(SRC_DIR)**/*.asm)
	mkdir -p ${BIN_DIR}
	nasm -Wall -f bin -i ${SRC_DIR} -o ${BIN_FILE} ${MAIN}
	mv ${BIN_FILE} ${STABLE_BIN_FILE}

.PHONY: clean
clean:
	rm -r ${BIN_DIR}

.PHONY: disassemble
disassemble: ${STABLE_BIN_FILE}
	objdump -b binary -Mintel -mi386 -Maddr16,data16 -D ${STABLE_BIN_FILE}

.PHONY: hex
hex: ${STABLE_BIN_FILE}
	xxd ${STABLE_BIN_FILE} | less

.PHONY: floppy
floppy: ${FLOPPY_FILE}

${FLOPPY_FILE}: ${STABLE_BIN_FILE}
	dd if=/dev/zero of=${FLOPPY_FILE} bs=1024 count=1440
	dd if=${STABLE_BIN_FILE} of=${FLOPPY_FILE} conv=notrunc
