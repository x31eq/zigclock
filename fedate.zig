const std = @import("std");
const feetime = @import("feetime.zig");

const Stamp = packed struct {
    week: i32,
    tick: u16,
    sec: u4 = 0,
};

pub fn main() !void {
    // Constant until I work out command line arguments
    const stamp = "f913.6b66";
    var week = try std.fmt.parseInt(i32, stamp[0..4], 16);
    if (week < 0xe000) {
        week += 0x20000;
    } else {
        week += 0x10000;
    }
    var tick = try std.fmt.parseInt(u16, stamp[5..9], 16);
    const packed_stamp = Stamp { .week = week, .tick = tick };
    const instant = @bitCast(feetime.Time, packed_stamp);

    const muggle = feetime.decode(instant);
    const stdout = try std.io.getStdOut();
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try std.fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.year, muggle.month, muggle.day,
            muggle.hour, muggle.min, muggle.sec);
    try stdout.write(mugglebuf);
}
