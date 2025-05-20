OUTPUT_FORMAT(elf64-littleaarch64)
ENTRY(__boot_entry__)

KERNEL_VIRT_START = 0xffffffff80000000;
KERNEL_STACK_SIZE = 0x4000;

SECTIONS {

    . = KERNEL_VIRT_START;
    
    __base__ = .;
    __kernel_start__ = .;

    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .text : {
        *(.text*)
    } : text

    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .rodata : {
        *(.rodata*)
    } : rodata

    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .data : {
        *(.data*)
    } : data

    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .bss : {
        *(.bss*)
        *(COMMON)

        . = ALIGN(16);
        . += KERNEL_STACK_SIZE;
    } : bss

    __kernel_end__ = .;
}
