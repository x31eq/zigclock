const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const now = feetime.currentTime();
    const quarter = @intCast(u32, now.quarter);
    const stdout = try std.io.getStdOut();
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
            @truncate(u8, quarter), now.week, now.halfday,
            now.hour, now.tick, now.sec);
    try stdout.write(arrbuf);

    const muggle = feetime.decode(now);
    var mugglebuf = "YYYY-mm-dd HH:MM:SS\n";
    _ = try std.fmt.bufPrint(mugglebuf[0..],
            "{}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}",
            muggle.year, muggle.month, muggle.day,
            muggle.hour, muggle.min, muggle.sec);
    try stdout.write(mugglebuf);
}
