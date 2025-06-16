# File System Calls | SystemElva Kernel

System calls in this group interact with, gather information about and
modify files, folders and  other items that may occur in a filesystem.
File system calls have the upper two bytes  of the system  call number
set to `0x0001`. The number  shown in the  data table  below tell  the
content of the lower two bytes of. Further information can be found in
the linked documents.

|  Number    |  Identifier                                           |
| ---------: | :---------------------------------------------------- |
|  `0x0001`  |  [open_file](./0001_open_file.md)                     |
|  `0x0002`  |  [close_file](./0002_close_file.md)                   |
|  `0x0003`  |  [get_metadata](./0003_get_metadata.md)               |
|  `0x0004`  |  [read_from_file](./0004_read_from_file.md)           |
|  `0x0005`  |  [write_to_file](./0005_write_to_file.md)             |
|  `0x0006`  |  [seek_in_file](./0006_seek_in_file.md)               |
|  `0x0007`  |  [sync_file_buffer](./0007_sync_file.md)              |
|  `0x0008`  |  [get_file_path](./0008_get_file_path.md)             |
|  `0x0009`  |  [get_work_folder](./0009_get_work_folder.md)         |
|  `0x000a`  |  [create_file](./000a_create_file.md)                 |
|  `0x000b`  |  [create_folder](./000b_create_folder.md)             |
|  `0x000c`  |  [create_link](./000c_create_link.md)                 |
|  `0x000d`  |  [create_pipe](./000d_create_pipe.md)                 |
|  `0x000e`  |  [map_memory_to_file](./000e_map_memory_to_file.md)   |
|  `0x000f`  |  [map_file_to_memory](./000f_map_file_to_memory.md)   |
|  `0x0010`  |  [unmap_file](./0010_unmap_file.md)                   |
|  `0x0011`  |  [unmap_memory](./0011_unmap_memory.md)               |
|  `0x0012`  |  [sync_file_mapping](./0012_sync_file_mapping.md)     |
|  `0x0013`  |  [chperms](./0013_chperms.md.md)                      |
|  `0x0014`  |  [chown](./0014_chown.md)                             |
|  `0x0015`  |  [get_perms](./0015_get_perms.md)                     |
|  `0x0016`  |  [get_file_owner](./0016_get_file_owner.md)           |
