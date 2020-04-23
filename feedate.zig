const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    var stamp = "000000:0000";
    try feetime.setStampFromArgs(stamp[0..], ':');
    const instant = feetime.Time {
        .quarter = try fmt.parseInt(i24, stamp[0..4], 16),
        .week = try fmt.charToDigit(stamp[4], 16),
        .halfday = try fmt.charToDigit(stamp[5], 16),
        .hour = try fmt.charToDigit(stamp[7], 16),
        .tick = try fmt.parseInt(u8, stamp[8..10], 16),
        .sec = try fmt.charToDigit(stamp[10], 16),
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
