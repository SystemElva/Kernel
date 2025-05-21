# SystemElva Kernel

## Debug and run:

```md
zig build         -- builds the kernel binaries and produces a disk image
zig build run     -- builds the kernel, prodices disk image and run it on qemu

# flags:
Dtarch=<arch>     -- Target ARCHtecture. Options are: x86_64, aarch64 (default is host)
```
