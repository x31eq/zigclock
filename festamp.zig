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
    try formatHex(quarter, 3, &buf);
    try formatHex(week, 1, &buf);
    try buf.append(".");
    try formatHex(halfday, 1, &buf);
    try formatHex(local.tm_hour, 1, &buf);
    try formatHex(ticks, 2, &buf);
    const stdout = try std.io.getStdOut();
    try buf.append("\n");
    try stdout.write(buf.list.items);
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
