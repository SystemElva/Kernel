# `open_file` (0x0001)

Open a file already existing on the disk, reserve resources for it and
return a globally unique descriptor structure for it.



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

The following errors are present in all categories:

- **InvalidFlags** (`0xff0001`)  
    Given if a  combination of  flags given is not allowed or a bit is
    set that doesn't correspond do a valid flag in the given context.

- **InvalidNextPointer** (`0xff0002`)  
    Given if the next pointer is neither `null` nor a valid pointer to
    memory region containing a command argument structure.

- **TooManyCommands** (`0xff0003`)  
    Given if the 255th node has a next-pointer that isn't `null`; i.e.
    if there are 256 or more commands in the chain.

### *Files* - specific errors

The following errors are present in this actions and all other actions
of the *Files* - category:

- **FileNotFound** (`0x018001`)  
    Given if the folder containing the file is accessible but the file
    wanted inside it couldn't be found.

- **InvalidDescriptorPointer** (`0x0018002`)  
    Given if the descriptor pointer  points to a memory region that is
    not mapped readalbe for the calling process.
 
### Action - specific Errors

The following errors are specific to only this action:

- **EmptyPath** (`0x001001`)  
    Given if  the path doesn't  contain  any characters; if  the first
    character found is `0x00`, the string terminator byte.

- **DisallowedPathCharacters** (`0x001002`)  
    Given if the path  contains  characters that aren't  allowed, like
    some signs that a particular  filesystem doesn't allow  or control
    characters.  This may also occur if an  invalid or undefined UTF-8
    code point is used.

- **PathTooLong** (`0x001003`)  
    Given if the encoded path is  too long. This only occurs if all of
    the characters until the limit is hit are allowed path characters.
    The limit more likely to be exceeded  is defined by the filesystem
    as SystemElva's limit is set conservatively as 16384 (2^14) bytes.

- **InvalidPathPointer** (`0x001004`)  
    Given if the pointer pointer to the path doesn't point to a memory
    region mapped accessible for the program issuing the system call.

- **PathNotAbsolute** (`0x001005`)  
    Given if the path to the file to open doesn't start with a forward
    slash, i.e. if it is not an absolute path.

- **InvalidOpenMode** (`0x001006`)  
    Given if `open_mode` has an invalid value that can't be understood
    correctly because of bits set wrong.

- **IsFolder** (`0x001007`)  
    Given if the folder  item pointed to by the path  is a folder or a
    link that points to a folder.

- **OpenModeNotAllowed** (`0x001008`)  
    Given if the calling process doesn't have the permissions to open
    the given file with the wanted open mode.


