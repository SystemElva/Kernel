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
