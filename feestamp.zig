const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const stdout = try std.io.getStdOut();

    const instant = try feetime.timeFromArgs();
    const quarter = @intCast(u32, instant.quarter);
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
            @truncate(u8, quarter), instant.week, instant.halfday,
            instant.hour, instant.tick, instant.sec);
    try stdout.write(arrbuf);
}
