const std = @import("std");
const mem = std.mem;
const feetime = @import("feetime.zig");

pub fn main() u8 {
    return mainDelegated("000000:0000"[0..]);
}

pub fn mainDelegated(stamp: []const u8) u8 {
    if (std.os.argv.len < 2) {
        std.debug.warn("Supply the hex timestamp on the command line\n");
        return 1;
    }
    if (printStampFromArgs(stamp)) {
        return 0;
    }
    else |_| {
        std.debug.warn("Bad timestamp\n");
    }
    return 2;
}

/// Unpack the arguments and print the result
pub fn printStampFromArgs(stamp: []const u8) !void {
    var stamp_out = "000000:0000";
    std.mem.copy(u8, stamp_out[0..], stamp);
    const stamp_arg = std.os.argv[1];
    const stamp_in = stamp_arg[0..mem.len(u8, stamp_arg)];
    var offset = mem.indexOfAny(u8, stamp, ".:").? + 1;
    if (mem.indexOfAny(u8, stamp_in, ".:")) |pos| {
        offset -= pos + 1;
    }
    mem.copy(u8, stamp_out[offset..], stamp_in);
    if (offset > 1) {
        var epoch_prefix: u32 = 0x1f;
        if (std.os.getenv("HEXEPOCH")) |epoch_arg| {
            if (std.fmt.parseInt(u32, epoch_arg, 10)) |epoch| {
                epoch_prefix = epoch / 64;
            }
            else |_| {
                std.debug.warn("Bad HEXEPOCH, using default\n");
            }
        }
        _ = try std.fmt.bufPrint(stamp_out[0..2], "{x:0>2}", epoch_prefix);
    }
    else if (offset > 0) {
        const epoch = try std.fmt.charToDigit(stamp_out[1], 16);
        stamp_out[0] = if (epoch < 0xe) '2' else '1';
    }
    const instant = try feetime.timeFromHex(stamp_out);
    var output_buffer = "YYYYY-mm-dd HH:MM:SS\n";
    const stdout = try std.io.getStdOut();
    try stdout.write(try instant.isoFormat(output_buffer[0..]));
}
