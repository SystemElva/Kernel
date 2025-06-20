const std = @import("std");
const root = @import("root");
const sys = root.system;

const debug = root.debug;

pub const Date = struct {
    day: u8,
    month: u8,
    year: u32,

    pub fn format(s: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, fmt: anytype) !void {
        fmt.write("{:0>4} - {:0>2} - {:0>2}", .{
            s.year, s.month, s.day
        });
    }
};

pub const Time = struct {
    secconds: u8,
    minutes: u8,
    hours: u8,

    pub fn format(s: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, fmt: anytype) !void {
        fmt.write("{:0>2}:{:0>2}:{:0>2}", .{
            s.hours, s.minutes, s.secconds,
        });
    }
};

pub const DateTime = struct {
    // Date
    day: u8,
    month: u8,
    year: u32,

    // Time
    secconds: u8,
    minutes: u8,
    hours: u8,

    pub fn get_date(s: @This()) Date {
        return .{
            .day = s.day,
            .month = s.month,
            .year = s.year
        };
    }

    pub fn get_time(s: @This()) Time {
        return .{
            .secconds = s.secconds,
            .minutes = s.minutes,
            .hours = s.hours
        };
    }

    pub fn format(s: *const @This(), comptime _: []const u8, _: std.fmt.FormatOptions, fmt: anytype) !void {
        try fmt.print("{:0>2}:{:0>2}:{:0>2} {:0>4} - {:0>2} - {:0>2}", .{
            s.hours, s.minutes, s.secconds,
            s.year, s.month, s.day
        });
    }
};


const internal = switch (sys.arch) {
    .x86_64 => @import("x86_64/time.zig"),
    else => unreachable
};

var elapsed_ticks: usize = 0; 

pub const timestamp: fn () u64 = internal.timestamp;
pub const get_date: fn () Date = internal.get_date;
pub const get_time: fn () Time = internal.get_time;
pub const get_datetime: fn () DateTime = internal.get_datetime;

/// The elapsed ticks since the start of the
/// timer. Elapsed ticks should be in milisseconds,
/// but not trully guaranteed
pub fn get_elapsed_ticks() usize { return elapsed_ticks; }

pub fn init() void {
    // 0x20 = 32
    sys.interrupts.set_vector(0x20, timer_int, .kernel);
}

fn timer_int(_: *sys.TaskContext) void {

    elapsed_ticks += 1;
    debug.print("tick! {}\n", .{elapsed_ticks});

}
