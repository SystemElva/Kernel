# System Calls | SystemElva Kernel

The documents in this directory explain the system calls that the user
space of an Elva system can use.

The set of system calls SystemElva  uses is subdivided into separated,
categories, each  of which handles a specific part  of interaction and
may not  be available to a program in case that it  lacks permissions:

|  Numbers   |  Category Name                               |
| ---------: | :------------------------------------------- |
|  `0x0001`  |  Files                                       |
|  `0x0002`  |  Processes & Communication                   |
|  `0x0003`  |  Memory Management                           |
|  `0x0004`  |  Executables                                 |
|  `0x0005`  |  Users & Permissions                         |
|  `0x0006`  |  Network                                     |
|  `0x00ff`  |  Miscellaneous                               |
|  `0x0100`  |  Driver Registration                         |
|  `0x0200`  |  Drivers-only Hardware-Interaction           |
|  `0xffff`  |  System Call Interface - related             |

