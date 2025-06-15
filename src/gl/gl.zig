const std = @import("std");
const root = @import("root");
const debug = root.debug;

var framebuffer: []Pixel = undefined;
var height: usize = 0;
var width: usize = 0;
var pps: usize = 0;

var font_width: usize = 0;
var font_height: usize = 0;

var char_height: usize = 0;
var char_width: usize = 0;

const font: [2][]const u8 = .{
    @embedFile("assets/bitfont.bf"),
    @embedFile("assets/monofont.bf"),
};
const Pixel = packed struct(u32) {
    blue: u8,
    green: u8,
    red: u8,
    _ignored: u8 = 0,

    pub fn rgb(r: u8, g: u8, b:u8) Pixel {
        return .{
            .red = r,
            .green = g,
            .blue = b
        };
    }
};

pub fn init(fb: []u8, h: usize, w: usize, p: usize) void {

    framebuffer.ptr = @ptrCast(@alignCast(fb.ptr));
    framebuffer.len = fb.len / 4;

    height = h;
    width = w;
    pps = p;

    font_width = std.mem.readInt(u32, font[0][0..4], .big);
    font_height = std.mem.readInt(u32, font[0][4..8], .big);

    char_width = @divFloor(width, font_width) - 2;
    char_height = @divFloor(height, font_height) - 2;
}

var char_x: usize = 0;
var char_y: usize = 0;
pub fn clear() void {
    for (0..framebuffer.len) |i| framebuffer[i] = .rgb(0, 0, 200);
    char_x = 0;
    char_y = 0;
}
pub fn draw_char(c: u8) void {

    if (char_x > char_width or char_y > char_height) return;

    const char_base = font[1][0x10 + (c * 2 * font_height) ..];

    const gx = char_x * font_width + 20;
    const gy = char_y * font_height + 20;

    for (0..font_height) |y| {

        const c_line = std.mem.readInt(u16, char_base[y * 2..][0..2], .little);

        for (0..font_width) |x| {

            if ((std.math.shr(u16, c_line, font_width - x) & 1) != 0) {
                framebuffer[gx + x + (gy + y) * height] = .rgb(255, 255, 255);
            }

        }
    }

    char_x += 1;
}
pub fn set_cursor_pos(x: usize, y: usize) void {
    char_x = x;
    char_y = y;
}

