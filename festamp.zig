const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const now = feetime.currentTime();
    const quarter = @intCast(u16, now.quarter & 0xfff);
    const stdout = try std.io.getStdOut();
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>3}{x:0>1}.{x:0>1}{x:0>1}{x:0>2}",
            quarter, now.week, now.halfday, now.hour, now.tick);
    try stdout.write(arrbuf);
}
