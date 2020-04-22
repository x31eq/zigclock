const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    var instant: feetime.Time = undefined;
    const stamp = std.os.argv[1];
    if (stamp[0] == ':') {
        // time with no date
        instant = feetime.Time {
            .quarter = 1984 * 4,
            .week = 0,
            .halfday = 0,
            .hour = try fmt.charToDigit(stamp[1], 16),
            .tick = try fmt.parseInt(u8, stamp[2..4], 16),
            .sec = try fmt.charToDigit(stamp[4], 16),
        };
    }
    else {
        var quarter = try fmt.parseInt(i24, stamp[0..2], 16);
        instant = feetime.Time {
            .quarter = quarter + 0x1f00,
            .week = try fmt.charToDigit(stamp[2], 16),
            .halfday = try fmt.charToDigit(stamp[3], 16),
            .hour = try fmt.charToDigit(stamp[5], 16),
            .tick = try fmt.parseInt(u8, stamp[6..8], 16),
            .sec = try fmt.charToDigit(stamp[8], 16),
        };
    }
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
