// Implementation of the task's context and extra
// information that should not be shared by the process

// This structure should only indicate a single task, an asyncronous
// procedure in execution. Each task represents a CPU state and is
// schedued to do multitasking.

const std = @import("std");
const root = @import("root");

tid: u32,
context: root.system.TaskContext,


