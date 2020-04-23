const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    const stamp_arg = std.os.argv[1];
    const stamp_in = stamp_arg[0..std.mem.len(u8, stamp_arg)];
    var stamp = "000000:0000";
    const offset = 6 - std.mem.indexOfScalar(u8, stamp_in, ':').?;
    std.mem.copy(u8, stamp[offset..], stamp_in);
    var quarter = try fmt.parseInt(i24, stamp[0..4], 16);
    if (offset > 1) {
        const epoch = try fmt.parseInt(
                i24, std.os.getenv("HEXEPOCH") orelse "1984", 10);
        quarter += epoch * 4;
    }
    else if (offset > 0) {
        if (quarter < 0xe00) {
            quarter += 0x2000;
        }
        else {
            quarter += 0x1000;
        }
    }
    const instant = feetime.Time {
        .quarter = quarter,
        .week = try fmt.charToDigit(stamp[4], 16),
        .halfday = try fmt.charToDigit(stamp[5], 16),
        .hour = try fmt.charToDigit(stamp[7], 16),
        .tick = try fmt.parseInt(u8, stamp[8..10], 16),
        .sec = try fmt.charToDigit(stamp[10], 18),
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
