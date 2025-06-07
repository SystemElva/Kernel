# Appendices

## Appendix A

This appendix  contains common definitions of various  structures used
throughout the system call interface. The definitions are given in the
C programming language's syntax, as it is widely known and familiar to
most low-level developers.

It is assumed that no padding is  done to the structures and that they
are stored, as typical for x86_64, with little-endian encoding.

### File-related

```C
enum SvkFileOpenMode
{
    SVK_OPEN_MODE_READ_ONLY     = 1,
    SVK_OPEN_MODE_WRITE_ONLY    = (1 << 1),
    SVK_OPEN_MODE_EXECUTE       = (1 << 2),

    SVK_OPEN_MODE_READ_WRITE    = 1 | (1 << 1),
    SVK_OPEN_MODE_FULL_ACCESS   = 1 | (1 << 1) | (1 << 2),
};

struct SvkFileDescriptor
{
    uint64_t creator_process;
    uint64_t file_serial;
};

struct SvkTimestamp
{
    uint16_t millisecond;
    uint16_t year;
    uint32_t second_in_year;
};

struct SvkFileStatistics
{
    uint64_t length;

    uint64_t owner_id;
    uint64_t group_id;

    struct SvkTimestamp creation_timestamp;
    struct SvkTimestamp modification_timestamp;
    struct SvkTimestamp access_timestamp;

    uint8_t name[256];
};
```

## Appendix B

> @todo: Generic flags field

## Appendix C

This appendix contains a list of  all error definitions to be found in
the system call ABI of SystemElva, including the corresponding numeric
identifier and a short description.

- **InvalidFlags** (`0x000001`)  
    Given if a  combination of  flags given is not allowed or a bit is
    set that doesn't correspond do a valid flag in the given context.

- **InvalidNextPointer** (`0x000002`)  
    Given if the next pointer is neither `null` nor a valid pointer to
    memory region containing a command argument structure.

- **TooManyCommands** (`0x000003`)  
    Given if the 255th node has a next-pointer that isn't `null`; i.e.
    if there are 256 or more commands in the chain.

- **FileNotFound** (`0x000004`)  
    Given if the folder containing the file is accessible but the file
    wanted inside it couldn't be found.

- **InvalidDescriptorPointer** (`0x000005`)  
    Given if the descriptor pointer  points to a memory region that is
    not mapped readable for the calling process.

- **EmptyPath** (`0x000006`)  
    Given if  the path doesn't  contain  any characters; if  the first
    character found is `0x00`, the string terminator byte.

- **DisallowedPathCharacters** (`0x000007`)  
    Given if the path  contains  characters that aren't  allowed, like
    some signs that a particular  filesystem doesn't allow  or control
    characters.  This may also occur if an  invalid or undefined UTF-8
    code point is used.

- **PathTooLong** (`0x000008`)  
    Given if the encoded path is  too long. This only occurs if all of
    the characters until the limit is hit are allowed path characters.
    The limit more likely to be exceeded  is defined by the filesystem
    as SystemElva's limit is set conservatively as 16384 (2^14) bytes.

- **InvalidPathPointer** (`0x000009`)  
    Given if the pointer pointer to the path doesn't point to a memory
    region mapped accessible for the program issuing the system call.

- **PathNotAbsolute** (`0x00000a`)  
    Given if the path to the file to open doesn't start with a forward
    slash, i.e. if it is not an absolute path.

- **InvalidOpenMode** (`0x00000b`)  
    Given if `open_mode` has an invalid value that can't be understood
    correctly because of unused or conflicting bits being set.

- **IsFolder** (`0x00000c`)  
    Given if the folder  item pointed to by the path  is a folder or a
    link that points to a folder, with neither case being supported.

- **OpenModeNotAllowed** (`0x00000d`)  
    Given if the calling process doesn't have the permissions to open
    the given file with the requested open mode.
