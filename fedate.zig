const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    // Constant until I work out command line arguments
    const stamp = "f913.6b66";
    var quarter = try std.fmt.parseInt(i24, stamp[0..3], 16);
    if (quarter < 0xe00) {
        quarter += 0x2000;
    } else {
        quarter += 0x1000;
    }

    const instant = feetime.Time {
        .quarter = quarter,
        .week = @truncate(u4, try std.fmt.charToDigit(stamp[3], 16)),
        .halfday = @truncate(u4, try std.fmt.charToDigit(stamp[5], 16)),
        .hour = @truncate(u4, try std.fmt.charToDigit(stamp[6], 16)),
        .tick = try std.fmt.parseInt(u8, stamp[7..9], 16),
    };
    const muggle = feetime.decode(instant);
    const stdout = try std.io.getStdOut();
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try std.fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.year, muggle.month, muggle.day,
            muggle.hour, muggle.min, muggle.sec);
    try stdout.write(mugglebuf);
}
