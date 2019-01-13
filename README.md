# Nebula

## Known issues

Currently none.

## Used foreign code

- [Floppy Bird bootloader](https://github.com/icebreaker/floppybird/blob/master/src/boot.asm) ([LICENSE](LICENSES/icebreaker_floppybird))

## Code guidelines

- Procedures should be properly documented (see below).
- Macro and definition names should always use UPPER_CASE (MACRO_CASE).
- All other names should be written in snake_case (c_case) or flatcase if saving space is really important.

## Procedure documentation

| Parameter | Descrption                                  |
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
; @out  REGSITER    Output register description.
; @reg  REGISTER, REGISTER, RESGITER
; @pre  Precondition.
; @post Postcondition.
procedure_name:
    ; procedure code
    ret
```
