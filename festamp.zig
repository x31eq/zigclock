const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const now = feetime.currentTime();
    const date = @intCast(u32, now.quarter) * 16 + now.week;
    const stdout = try std.io.getStdOut();
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>4}.{x:0>1}{x:0>1}{x:0>2}",
            @truncate(u16, date), now.halfday, now.hour, now.ticks);
    try stdout.write(arrbuf);
}
