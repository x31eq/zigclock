const std = @import("std");
const time = @cImport(@cInclude("time.h"));

const Time = packed struct {
    quarter: i32,
    week: u8,
    halfday: u8,
    hour: u8,
    ticks: u8,
};

pub fn main() !void {
    const now = currentTime();
    const date = @intCast(u32, now.quarter) * 16 + now.week;
    var buf = try std.Buffer.init(std.debug.global_allocator, "");
    try formatHex(@truncate(u16, date), &buf);
    try buf.append(".");
    try hexDigit(now.halfday, &buf);
    try hexDigit(now.hour, &buf);
    try formatHex(now.ticks, &buf);
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
    var qday = @intCast(u16, month) / 3;
    if (month == 2 or month == 11) {
        qday += 1;
    }
    qday += @intCast(u16, local.tm_mday + 5 - local.tm_wday);
    var ticks = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    return Time {
        .quarter = year * 4 + @divFloor(month, 3),
        .week = @truncate(u8, qday / 7),
        .halfday = @intCast(u8, local.tm_wday * 2)
                    + @boolToInt(local.tm_hour > 11),
        .hour = @intCast(u8, local.tm_hour) % 12,
        .ticks = @truncate(u8, @intCast(u32, ticks * 16) / 15),
    };
}

/// Format a number as hex appended to the given buffer
/// zero-padded with width determined by the type.
fn formatHex(value: var, buf: *std.Buffer) !void {
    // There must be a better way.
    // This is the best I can work out for now.
    const bits = @typeInfo(@typeOf(value)).Int.bits;
    return std.fmt.formatIntValue(
            value,
            "x",
            std.fmt.FormatOptions{ .width = bits / 4, .fill = '0' },
            buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
}

fn hexDigit(value: var, buf: *std.Buffer) !void {
    // There must be a better way.
    // This is the best I can work out for now.
    return std.fmt.formatIntValue(
            value,
            "x",
            std.fmt.FormatOptions{ .width = 1, .fill = '0' },
            buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
}
