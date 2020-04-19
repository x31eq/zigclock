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
}
