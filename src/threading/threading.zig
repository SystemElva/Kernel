const root = @import("root");
const sys = root.system;

pub const Process = @import("processes/Process.zig");
pub const Task = @import("tasks/Task.zig");

pub const TaskContext = sys.TaskContext;

pub const procman = @import("processes/process_manager.zig");
pub const taskman = @import("tasks/task_manager.zig");


pub fn init() void {
    procman.init();
    taskman.init();
}
