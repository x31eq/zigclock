const std = @import("std");
const time = @cImport(@cInclude("time.h"));

pub fn main() !void {
    var local: time.tm = undefined;

    var timestamp = std.time.timestamp();
    _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    const quarter = @mod(year, 1024) * 4 + @divFloor(month, 3);
    var qday = @divFloor(month, 3);
    if (month == 2 or month == 11) {
        qday += 1;
    }
    const week = @divFloor(qday + local.tm_mday + 5 - local.tm_wday, 7);
    var halfday = local.tm_wday * 2;
    if (local.tm_hour > 11) {
        halfday += 1;
    }
    var ticks = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    ticks = @divFloor(ticks * 16,  15);

    var buf = try std.Buffer.init(std.debug.global_allocator, "");
    try std.fmt.formatIntValue(
            @intCast(u64, quarter),
            "x",
            std.fmt.FormatOptions{ .width = 3, .fill = '0' },
            &buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
    try std.fmt.formatIntValue(
            @intCast(u64, week),
            "x",
            std.fmt.FormatOptions{ .width = 1, .fill = '0' },
            &buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);

    const stdout = try std.io.getStdOut();
    try stdout.write(buf.list.items);
    try stdout.write(".");
    buf = try std.Buffer.init(std.debug.global_allocator, "");
    try std.fmt.formatIntValue(
            @intCast(u64, halfday),
            "x",
            std.fmt.FormatOptions{ .width = 1, .fill = '0' },
            &buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
    try std.fmt.formatIntValue(
            @intCast(u64, local.tm_hour),
            "x",
            std.fmt.FormatOptions{ .width = 1, .fill = '0' },
            &buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
    try std.fmt.formatIntValue(
            @intCast(u64, ticks),
            "x",
            std.fmt.FormatOptions{ .width = 2, .fill = '0' },
            &buf,
            @typeOf(std.Buffer.append).ReturnType.ErrorSet,
            std.Buffer.append);
    try stdout.write(buf.list.items);
    try stdout.write("\n");
}
