const std = @import("std");
const time = @cImport(@cInclude("time.h"));

const Time = struct {
    quarter: i32,
    week: i32,
    halfday: i32,
    hour: i32,
    ticks: i32,
};

pub fn main() !void {
    const now = currentTime();
    var buf = try std.Buffer.init(std.debug.global_allocator, "");
    try formatHex(@mod(now.quarter, 0x1000), 3, &buf);
    try formatHex(now.week, 1, &buf);
    try buf.append(".");
    try formatHex(now.halfday, 1, &buf);
    try formatHex(now.hour, 1, &buf);
    try formatHex(now.ticks, 2, &buf);
    const stdout = try std.io.getStdOut();
    try buf.append("\n");
    try stdout.write(buf.list.items);
}

fn currentTime() Time {
    var local: time.tm = undefined;

    var timestamp = std.time.timestamp();
    _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    var qday = @divFloor(month, 3);
    if (month == 2 or month == 11) {
        qday += 1;
    }
    var halfday = local.tm_wday * 2;
    if (local.tm_hour > 11) {
        halfday += 1;
    }
    var ticks = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    return Time {
        .quarter = year * 4 + @divFloor(month, 3),
        .week = @divFloor(qday + local.tm_mday + 5 - local.tm_wday, 7),
        .halfday = halfday,
        .hour = @mod(local.tm_hour, 12),
        .ticks = @divFloor(ticks * 16,  15),
    };
}

/// Format a number as hex appended to the given buffer
/// zero-padded with the given width.
fn formatHex(value: var, width: u32, buf: *std.Buffer) !void {
    // There must be a better way.
    // This is the best I can work out for now.
    return std.fmt.formatIntValue(
            @intCast(u64, value),
            "x",
            std.fmt.FormatOptions{ .width = width, .fill = '0' },
            buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
}
