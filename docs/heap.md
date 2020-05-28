# Heap memory model

## Architecture

The 4 GiB of memory addressable using 32-bit addresses is split into 16 MiB blocks.
Everything except for the heap resides within the first block (kernel code, static data, stack).
The 16 MiB address is the top of the stack and the beginning of the heap.

### Three levels of tables and memory blocks used for heap organization

1. Primary table
    - Describes allocation of the 16 MiB top-level blocks.
    - Contains 32-bit entries. Requires 256 * 4 B = 1 KiB of space somewhere in the first block.
    - Blocks have an address in the format `0xZZ000000`, where `ZZ` is an index of the corresponding entry in the table.
2. Secondary table
    - Describes allocation of 64 KiB sub-blocks within the block.
    - Contains 32-bit entries. Theoretically also requires only 256 * 4 B = 1 KiB of space, but in reality the whole first 64 KiB sub-block is used for this table, effectively wasting 63 KiB of memory space.
    - Block address format is `0xZZYY0000`, where `ZZ` is index into primary table and `YY` is index into secondary table.
3. Tertiary table
    - Describes allocation of 256 B blocks - the smallest amount of memory that can be allocated on the heap using this architecture.
    - Contains 8-bit entries.
    - Block address format is `0xZZYYXX00`, where `XX` is index into the tertiary table. The rest matches the secondary table.

Each table contains 256 numeric values of varying sizes (based on the level of the table).
Each value represents the number of used/allocated bytes in the corresponding block.

The primary table is located in the static data section (`.data`), somewhere below the 16 MiB mark.
All other tables are always located in the first sub-block of their parent block,
which is technically true for the primary table as well,
but the first 16 MiB block contains a lot more than just the primary table.

### Types of memory blocks

#### Data block

Table entry contains the number of allocated minimal/tertiary/256-byte blocks.
This value can be later used for reallocation.

When multiple data blocks are allocated at once, on any allocation table level,
they must always form one continuous memory block within their parent block.

#### Nested table block

These are split into their own 256 sub-blocks.
The first one contains another lower-level sub-table.

Tertiary (256 byte) blocks can never contain a nested table due to their already small size.
This is why allocating a large quantity of very small memory blocks (just a few bytes long) is undesirable.

### Table entries

Every entry in every table, regardless of its level, contains a single numeric value.
In primary and secondary tables, this value is always a 32-bit integer.
In the tertiary tables, it is only an 8-bit integer because the tertiary sub-blocks are only 256 bytes long
and the table in the first sub-block needs to describe all 256 of the sub-blocks => 1 byte per table entry.

The values in the table entries represent the number of 256 byte blocks necessary to perform the allocation.
This is the allocation size divided by 256 and then rounded up.

Here is the NASM implementation of the entry value calculation, assuming that the allocation size is in `EAX`.
I believe some people may find it easier to understand than the natural language description.

```nasm
add eax, 0xFF
shr eax, 8
```

## Allocation procedure - `malloc`

**TBD**

## Release/de-allocation procedure - `free`

**TBD**

## Reallocation procedure - `realloc`

**TBD**

## Examples of allocation

### 0x1 - 0x100 bytes

The size is less or equal to 256 B.
It can fit into a single cell of a tertiary table.
The corresponding table entry will contain `0x01`,
indicating that exactly 1 cell, beginning at the entry's index, was allocated.

### 0x101 - 0xFF00 bytes

This is too much data for a single tertiary block.
However, it can still fit into a tertiary table, taking up multiple tertiary blocks
(up to 255, which would practically mean one entire secondary block).
All of the allocated tertiary blocks must be within a single parent secondary block.
The table entry representing the first block used for this allocation
will contain the number of allocated blocks.
Every following entry will contain a value decreased by one until zero is reached.

### 0xFF01 - 0x1_0000 bytes

This is exactly the right size of data for a single secondary block.
The table entry will contain `0x100` = 256 tertiary blocks = single secondary block.
The value of the following table entry will be in no way related to this one.
The allocated secondary block will NOT contain the secondary allocation table.

### 0x1_0001 - 0xFF_0000 bytes

This requires the allocation of multiple secondary blocks.
The process is similar to the allocation of multiple tertiary block,
but the corresponding table entry value is 32-bit instead of 8-bit.

### 0xFF_0001 - 0x100_0000 bytes

This will result in the allocation of a single primary block in the primary allocation table,
with the table entry containing the value `0x10000` = 65536 tertiary blocks = 256 secondary blocks.

### 0x100_0001 - 0xFF00_0000 bytes

This is the largest possible type of an allocation using multiple
primary blocks recorded in the primary allocation table.
Everything else is just like the allocation of multiple secondary blocks.
