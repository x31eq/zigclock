const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const stdout = try std.io.getStdOut();

    const instant = try feetime.timeFromArgs();
    const quarter = @intCast(u16, instant.quarter & 0xfff);
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>3}{x:0>1}.{x:0>1}{x:0>1}{x:0>2}",
            quarter, instant.week, instant.halfday,
            instant.hour, instant.tick);
    try stdout.write(arrbuf);
}
