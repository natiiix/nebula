# Nebula

## Code guidelines

- Procedures should be properly documented (see below).
- Macro and definition names should always use UPPER_CASE (MACRO_CASE).
- All other names should be written in snake_case (c_case) or flatcase if saving space is really important.

## Procedure documentation

| Parameter | Description                                 |
| --------- | ------------------------------------------- |
| `@desc`   | Procedure description.                      |
| `@in`     | Name and description of an input register.  |
| `@out`    | Name and description of an output register. |
| `@reg`    | Comma-separated list of modified registers. |
| `@pre`    | Precondition.                               |
| `@post`   | Postcondition.                              |

- Register names should be written in uppercase in documentation to make stand out.
- Each part of description parameters should be 4-space aligned to improve readability.
- Sentences should be terminated with a period, even if a description consists of just a single sentence.
- It is possible to use `@in` and `@out` with labels referring to variables in memory in place of registers, but it may be worth considering to use `@pre` and `@post` in such situations instead.
- Output registers mentioned in `@out` do not have to be mentioned again in `@reg` as modified registers to avoid redundance.

```nasm
; @desc Procedure description.
; @in   REGISTER    Input register description.
; @out  REGISTER    Output register description.
; @reg  REGISTER, REGISTER, REGISTER
; @pre  Precondition.
; @post Postcondition.
procedure_name:
    ; procedure code
    ret
```

## `Boot failed: Could not read from CDROM (code 0004)`

This error is produced by QEMU when unable to boot from the given CD image.
Presumably, other virtual machine emulators have a similar error message.

It seems to happen when the `grub-mkrescue` command was executed on a host system booted from EFI.
Creating the image this way may render it impossible to boot from a regular BIOS, such as those emulated by QEMU or VirtualBox.

It is possible to run into this issue when running Ubuntu on Windows 10 via WSL.
In this case, the solution to this mysterious error can actually be very simple.
Installing the `grub-pc-bin` package is often enough to completely resolve it.
This can be done by issuing the following command in your terminal.

```sh
sudo apt-get install -y grub-pc-bin
```

## Credits

Various parts of the code have been inspired by the [OSDev Wiki](https://wiki.osdev.org/), especially the parts related to low-level initialization (GDT, IDT), hardware communication (writing to VGA text buffer, processing keyboard events) and the build process (Multiboot header, `nasm` and `ld` parameters, linker configuration file, using `grub-mkrescue` to build the bootable `.iso` disk image).

Formerly, the [Floppy Bird bootloader](https://github.com/icebreaker/floppybird/blob/master/src/boot.asm) was used for a sense of NASM purity.
However, due to its shortcomings (only supports bootloading ~8KiB worth of kernel), it has been since replaced by GRUB 2 for the sake of convenience.
