SRC_DIR=src/
SRC_MAIN=${SRC_DIR}main.asm

OBJ_DIR=obj/
OBJ_MAIN=${OBJ_DIR}main.o

CONFIG_DIR=config/
LINKER_FILE=${CONFIG_DIR}linker.ld
GRUB_CFG_FILE=${CONFIG_DIR}grub.cfg

BIN_DIR=bin/
BIN_FILE=${BIN_DIR}nebula.bin

ISO_DIR=iso/
ISO_BOOT_DIR=${ISO_DIR}boot/
ISO_GRUB_DIR=${ISO_BOOT_DIR}grub/
ISO_FILE=nebula.iso

NASM_FORMAT=elf32
NASM_FLAGS=-Werror=all
NASM_PARAMS=-f ${NASM_FORMAT} -i ${SRC_DIR} ${NASM_FLAGS}

LD_FORMAT=elf_i386
LD_FLAGS=--fatal-warnings
LD_PARAMS=-m ${LD_FORMAT} -T ${LINKER_FILE} ${LD_FLAGS}

.PHONY: all
all: ${ISO_FILE}

.PHONY: clean
clean:
	rm -rf ${BIN_DIR} ${OBJ_DIR} ${ISO_DIR} ${ISO_FILE}

${ISO_FILE}: ${GRUB_CFG_FILE} ${BIN_FILE}
	grub-file --is-x86-multiboot ${BIN_FILE}
	mkdir -p ${ISO_DIR} ${ISO_BOOT_DIR} ${ISO_GRUB_DIR}
	cp ${GRUB_CFG_FILE} ${ISO_GRUB_DIR}
	cp ${BIN_FILE} ${ISO_BOOT_DIR}
	grub-mkrescue -o $@ ${ISO_DIR}

${BIN_FILE}: ${LINKER_FILE} ${OBJ_MAIN}
	mkdir -p ${BIN_DIR}
	ld -o $@ ${LD_PARAMS} ${OBJ_MAIN}

${OBJ_MAIN}: $(shell find ${SRC_DIR} -name '*.asm')
	mkdir -p ${OBJ_DIR}
	nasm -o $@ ${NASM_PARAMS} ${SRC_MAIN}
