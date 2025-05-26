# `open_file` (0x0001)

Open a file already existing on the disk, reserve resources for it and
register and return a global descriptor structure for it.



## Argument Structure (C-Representation)

```C
struct SvkArgumentOpenFile
{
    uint32_t action;
    uint32_t flags;
    char *path;
    struct SvkFileDescriptor *descriptor_buffer;
    struct SvkFileOpenMode open_mode:8;

    uint8_t padding[31];
    void *chain_next;
};
```

> Structures and enumerations that are shared  between multiple system
> calls' argument structures are defined in another document, namely:
> [Appendix A](../Appendices.md#appendix-a).



## Argument Structure (Thorough Definition)

|  #   |  Offset  |  Length  |  Descriptor                           |
| ---: | :------: | :------- | :------------------------------------ |
|  0   |  `0x00`  |  4       |  `action`                             |
|  1   |  `0x04`  |  4       |  `flags`                              |
|  2   |  `0x08`  |  8       |  `path`                               |
|  3   |  `0x10`  |  8       |  `descriptor_buffer`                  |
|  4   |  `0x18`  |  1       |  `open_mode`                          |
|  5   |  `0x19`  |  31      |  `padding`                            |
|  6   |  `0x38`  |  8       |  `chain_next`                         |

0. `action`   
    Descriptor of  the action `os.systemelva.fs.open_file`,  i.e.: the
    category value (`0x0001`) in the  upper two bytes and the function
    number (`0x0001`) in the lower two bytes.

1. `flags`  
    The upper 20 bits of this value  are used for flags common between
    all  system calls, while the lower 12 may be used by  any specific
    system call. The  *generic flags* - component  (upper 20 bits) are
    defined in [Appendix B](../Appendices.md#appendix-b).

2. `path`  
    Absolute path  of the file  to open. If  a relative path  is given
    using this field, the system call will fail.

3. `descriptor_buffer`  
    Pointer to a *regular memory region*\* managed by the program that
    has issued the system call; a buffer which to write the descriptor
    of the newly opened file. The structure of a file descriptor is
    described in [Appendix A](../Appendices.md#appendix-a).

    \*: The term  *regular memory  region* denotes a  region of memory
    that is present  in RAM or may have been swapped  out to a farther
    cache level  (i.e. the disk). In  this case, it rules  out regions
    that represent mapped files, hardware I/O - buffers, et cetera.

4. `open_mode`  
    Type of usage this file descriptor should allow, i.e. whether the
    file should be readable, writable or both. The `enum` description
    can be found in [Appendix A](../Appendices.md#appendix-a).

5. `padding`  
    Bytes used to fill  up the structure to a final  size of 64 bytes.
    This is done for easier pool  allocation of multiple chained calls
    on the application's side.

6. `chain_next`  
    Pointer to the next call in the  chain of system calls to execute.
    This must be  either a valid pointer pointing to  a regular memory
    region owned by the program  or `null`, if the current node is the
    last one in the chain.



## Errors

> @todo: This section is still work-in-progress.
