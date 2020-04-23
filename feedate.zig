const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;
const string = @cImport(@cInclude("string.h"));

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    const epoch = try fmt.parseInt(
            i24, std.os.getenv("HEXEPOCH") orelse "1984", 10);
    const stamp_arg = std.os.argv[1];
    const arglen = string.strlen(stamp_arg);
    var stamp = "0000:0000";
    var offset: usize = 0;
    const divider: *u8 = string.strchr(stamp_arg, ':');
    offset = 4 - (@ptrToInt(divider) - @ptrToInt(stamp_arg));
    for (stamp_arg[0..arglen]) |c| {
        stamp[offset] = c;
        offset += 1;
    }
    var quarter = try fmt.parseInt(i24, stamp[0..2], 16);
    const instant = feetime.Time {
        .quarter = quarter + epoch * 4,
        .week = try fmt.charToDigit(stamp[2], 16),
        .halfday = try fmt.charToDigit(stamp[3], 16),
        .hour = try fmt.charToDigit(stamp[5], 16),
        .tick = try fmt.parseInt(u8, stamp[6..8], 16),
        .sec = try fmt.charToDigit(stamp[8], 16),
    };
    const muggle = feetime.decode(instant);
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.tm_year + 1900,
            @intCast(u32, muggle.tm_mon + 1),
            @intCast(u32, muggle.tm_mday),
            @intCast(u32, muggle.tm_hour),
            @intCast(u32, muggle.tm_min),
            @intCast(u32, muggle.tm_sec),
            );
    try stdout.write(mugglebuf);
}
