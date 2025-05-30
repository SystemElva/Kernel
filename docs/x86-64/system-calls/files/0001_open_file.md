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
    SvkFileDescriptor *descriptor_buffer;
    SvkFileOpenMode open_mode:8;

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
    using this field, the system call will fail. This must be given as
    ASCII or UTF-8  characters. The  full path may not be longer  than
    16384 or the limit of the underlying filesystem, whichever of them
    is lower. No path item may exceed the underlying filesystem's set
    limit (many filesystems allow 255 characters per element).

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

### General Errors

- **InvalidFlags** (`0xff01`)  
    Given if a  combination of  flags given is not allowed or a bit is
    set that doesn't correspond do a valid flag in the given context.

- **InvalidNextPointer** (`0xff02`)  
    Given if the next pointer is neither `null` nor a valid pointer to
    memory region containing a command argument structure.

- **MissingPermissiosn** (`0xff03`)  
    The requested action is not allowed for the calling process.

### Errors present in all *Files* system calls

- **FileNotFound** (`0xfe01`)  
    Given if the folder containing the file is accessible but the file
    wanted doesn't exist inside it.

- **PathNotAbsolute** (`0xfe02`)  
    Given if a path given as any path field isn't absolute. Paths must
    be absolute and direct (without `../`).

- **InvalidDescriptor** (`0xfe03`)  
    Given if the  descriptor doesn't  exist, if it has  been closed or
    isn't accessible to the caller process.

### Specific to this Action

- **EmptyPath** (`0x0101`)  
    Given if  the path doesn't  contain  any characters; if  the first
    character found is an *ASCII NUL* - byte.

- **DisallowedPathCharacters** (`0x0102`)  
    Given if the path  contains  characters that aren't  allowed, like
    some signs that a particular  filesystem doesn't allow  or control
    characters.  This may also occur if an  invalid or undefined UTF-8
    code point is used.

- **PathTooLong** (`0x0103`)  
    Given if the encoded path is  too long. This only occurs if all of
    the characters until the limit is hit are allowed path characters.
    The limit more likely to be exceeded is defined by the filesystem;
    SystemElva's limit is set as 16384 (2^14) bytes.

- **InvalidPathPointer** (`0x1404`)  
    Given if the pointer pointer to the path doesn't point to a memory
    region mapped accessible for the system call - issuing program.

- **InvalidOpenMode** (`0x0105`)  
    Given if `open_mode` has an invalid value that can't be understood
    correctly because of bits set wrong.

- **IsFolder** (`0x0106`)  
    Given if the folder  item pointed to by the path  is a folder or a
    link that points to a folder.

- **OpenModeNotAllowed** (`0x0107`)  
    Given if the calling process  doesn't have the permissions to open
    the given file with the wanted open mode.
