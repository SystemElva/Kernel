# Memory Management System Calls | SystemElva Kernel

System calls in this group are concerned purely with allocating memory
and freeing it  after its use, as well as giving the  system hints on
the memory's priority for the process.

|  Number    |  Identifier                                           |
| ---------: | :---------------------------------------------------- |
|  `0x0001`  |  [map_to_memory](./0001_alloc_pages.md)               |
|  `0x0002`  |  [free_pages](./0002_free_pages.md)                   |
|  `0x0003`  |  [remap_page](./0002_free_pages.md)                   |
|  `0x0004`  |  [get_page_metadata](./0003_get_page_metadata.md)     |
|  `0x0005`  |  [annotate_page](./0003_annotate_page.md)             |
