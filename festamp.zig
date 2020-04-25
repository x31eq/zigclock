const std = @import("std");
const feestamp = @import("feestamp.zig");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    var arrbuf = "xxxx.xxxx\n";
    return feestamp.mainDelegated(formatHex, arrbuf[0..]);
}

pub fn formatHex(instant: feetime.Time, buffer: []u8) !void {
    const quarter = @intCast(u32, instant.quarter & 0xfff);
    _ = try std.fmt.bufPrint(buffer,
                "{x:0>3}{x:0>1}.{x:0>1}{x:0>1}{x:0>2}",
                quarter, instant.week, instant.halfday,
                instant.hour, instant.tick);
}
