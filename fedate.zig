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
    const stamp_arg = std.os.argv[1];
    const arglen = string.strlen(stamp_arg);
    var stamp = "f000.00000";
    const divider: *u8 = string.strchr(stamp_arg, '.');
    const offset = 4 - (@ptrToInt(divider) - @ptrToInt(stamp_arg));
    std.mem.copy(u8, stamp[offset..], stamp_arg[0..arglen]);
    var quarter = try fmt.parseInt(i24, stamp[0..3], 16);
    if (quarter < 0xe00) {
        quarter += 0x2000;
    } else {
        quarter += 0x1000;
    }

    const instant = feetime.Time {
        .quarter = quarter,
        .week = try fmt.charToDigit(stamp[3], 16),
        .halfday = try fmt.charToDigit(stamp[5], 16),
        .hour = try fmt.charToDigit(stamp[6], 16),
        .tick = try fmt.parseInt(u8, stamp[7..9], 16),
        .sec = try fmt.charToDigit(stamp[9], 16),
    };
    const muggle = feetime.decode(instant);
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0<2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.tm_year + 1900,
            @intCast(u32, muggle.tm_mon + 1),
            @intCast(u32, muggle.tm_mday),
            @intCast(u32, muggle.tm_hour),
            @intCast(u32, muggle.tm_min),
            @intCast(u32, muggle.tm_sec),
            );
    try stdout.write(mugglebuf);
}
