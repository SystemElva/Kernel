// Implementation of the process unit
// A process unit structure represents the
// information about a process in execution,
// it system dependences and permissions.
// A process can contain multiple tasks, allowing
// easy multitheading.

const std = @import("std");
const root = @import("root");
const threading = root.threading;
const scheduler = threading.scheduler;
const auth = root.auth;

const Task = threading.Task;
const TaskEntry = *const fn (?*anyopaque) callconv(.c) isize;
const TaskContext = root.threading.TaskContext;

const allocator = root.mem.heap.kernel_allocator;

// Process general info
process_id: u32,
name: []const u8,
user: *auth.User,
privilege: root.system.Privilege,

// Tasks and related
tasks: []?*Task,
task_rover: usize = 0,

// Timestamps
creation_timestamp: u64,

// Memory data
// TODO allocated memory data

pub fn create_task(s: *@This(), entry: TaskEntry, stack: *anyopaque, priority: u8) !*Task {

    const tid = b: {

        if (s.task_rover > s.tasks.len) try s.enlarge_task_list();

        for (0..3) |_| {
            var i = s.task_rover;
            while (i < s.tasks.len) : (i += 1)
                if (s.tasks[i] == null) {
                    s.task_rover = i+1;
                    break :b i;
                };
            try s.enlarge_task_list();
        }
        @panic("pain");

    };

    const ntask = try allocator.create(Task);
    ntask.* = .{
        .task_id = @intCast(tid),
        .priority = priority,
        .state = .Ready,
        .context = std.mem.zeroes(TaskContext),
        .process = s,
        .creation_timestamp = root.system.time.timestamp(),
    };
    s.tasks[tid] = ntask;

    ntask.context.set_privilege(s.privilege);
    ntask.context.set_flags(.{
        .carry = false,
        .overflow = false,
        .sign = false,
        .zero = false,
        .interrupt = true,
    });
    ntask.context.set_instruction_ptr(@intFromPtr(entry));
    ntask.context.set_stack_ptr(@intFromPtr(stack));

    scheduler.append_task(ntask);
    return ntask;
}

fn enlarge_task_list(s: *@This()) !void {
    const new_size = @max(1, s.tasks.len + (std.math.divCeil(usize,s.tasks.len, 2) catch unreachable));
    const new_list = try allocator.alloc(?*Task, new_size);
    @memcpy(new_list[0 .. s.tasks.len], s.tasks[0..s.tasks.len]);
    @memset(new_list[s.tasks.len..new_size], null);
    allocator.free(s.tasks);
    s.tasks = new_list;
}
