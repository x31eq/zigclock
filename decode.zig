const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return;
    }
    var stamp = "00000.00000";
    const stamp_arg = std.os.argv[1];
    const stamp_in = stamp_arg[0..std.mem.len(u8, stamp_arg)];
    if (std.mem.indexOfScalar(u8, stamp_in, ':')) |_| {
        stamp = "000000:0000";
        try feetime.setStampFromArgs(stamp[0..], ':');
        std.mem.copy(u8, stamp[6..], stamp[7..]);
    }
    else {
        try feetime.setStampFromArgs(stamp[0..], '.');
        std.mem.copy(u8, stamp[5..], stamp[6..]);
    }
    const instant = feetime.Time {
        .quarter = try fmt.parseInt(i24, stamp[0..4], 16),
        .week = try fmt.charToDigit(stamp[4], 16),
        .halfday = try fmt.charToDigit(stamp[6], 16),
        .hour = try fmt.charToDigit(stamp[6], 16),
        .tick = try fmt.parseInt(u8, stamp[7..9], 16),
        .sec = try fmt.charToDigit(stamp[9], 16),
    };
    try stdout.write(try feetime.isoFormat(instant));
}
