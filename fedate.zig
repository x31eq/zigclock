const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    var stamp = "00000.00000";
    try feetime.setStampFromArgs(stamp[0..]);
    const instant = try feetime.timeFromHex(stamp);
    try stdout.write(try feetime.isoFormat(instant));
}
