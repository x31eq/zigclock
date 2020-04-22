const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    const stamp = std.os.argv[1];
    var quarter = try std.fmt.parseInt(i24, stamp[0..2], 16);

    const instant = feetime.Time {
        .quarter = quarter + 0x1f00,
        .week = try std.fmt.charToDigit(stamp[2], 16),
        .halfday = try std.fmt.charToDigit(stamp[3], 16),
        .hour = try std.fmt.charToDigit(stamp[5], 16),
        .tick = try std.fmt.parseInt(u8, stamp[6..8], 16),
        .sec = try std.fmt.charToDigit(stamp[8], 16),
    };
    const muggle = feetime.decode(instant);
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try std.fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.year, muggle.month, muggle.day,
            muggle.hour, muggle.min, muggle.sec);
    try stdout.write(mugglebuf);
}
