# Page Mapping API

This file describles how to communicate and interact with the page mapping API in diferent systems.
This API allows to map, remap and unmap memory pages for specific addressess with specific permissions.

All the API access is inside the `root.system.paging` namespace


## Common Data Structures
```rust
pub const Attributes = packed struct(u16) {
  // access permitions
  read: bool = true,
  write: bool = true,
  execute: bool = false,
  
  // general attributes
  privileged: bool = false,
  disable_cache: bool = false,
  unitialized: bool = false,
  lock: bool = false,
  interrupt: bool = false,
  
  // automatic grow
  growns_up: bool = false,
  growns_down: bool = false,
  
  _unused_: u7 = 0
}
```

| Offset | Field | length | Description |
|:------:|:-----:|:------:|:------------|
| 0x00   | read          | 1 | Requests page reading permission |
| 0x01   | write         | 1 | Requests page writing permission |
| 0x02   | execute       | 1 | Requests page execution permission |
| 0x03   | privileged    | 1 | Cause a page fault if acessed from user mode |
| 0x04   | disable_cache | 1 | Disables CPU caching car this page |
| 0x05   | unitialized   | 1 | Do not resed page data (unsafe) |
| 0x06   | lock          | 1 | Locks the page in RAM, disabling swap |
| 0x07   | interrupt     | 1 | Creates a virtual page that calls a user interrupt when adressed |
| 0x08   | growns_up     | 1 | Indicates that the page must grow automatically if higher unmapped addresses are called |
| 0x09   | growns_down   | 1 | Indicates that the page must grow automatically if lower unmapped addresses are called |

```rust
pub const MMapError = error {
  AddressAlreadyMapped,
  AddressNotMapped
};
```

## Functions

```rust
pub fn map_single_page(phys_base: usize, virt_base: usize, size: usize, attributes: Attributes) MMapError!void
```
Maps a single page of the designated size with the designated attributes. \
`size` must be a base 2 expoent. \
Do not checks if the physical address is valid.

```rust
pub fn map_range(phys_base: usize, virt_base: usize, length: usize, attributes: Attributes) MMapError!void
```
Maps a physical range to the specified virtual range.
Do not checks if the physical addresses are valid.

```rust
pub fn unmap_single_page(virt_base: usize) MMapError!void
```
Unmaps a single page at the designated virtual address.


```rust
pub fn unmap_range(virt_base: usize, length: usize) MMapError!void
```
Unmaps a range at the designated virtual address and length.
