const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        std.debug.warn("Supply the hex timestamp on the command line\n");
        return 1;
    }
    var stamp = "000000:0000";
    if (feetime.setStampFromArgs(stamp[0..])) {
        if (feetime.timeFromHex(stamp)) |instant| {
            var output_buffer = "YYYYY-mm-dd HH:MM:SS\n";
            try stdout.write(try instant.isoFormat(output_buffer[0..]));
            return 0;
        }
        else |_| {
            std.debug.warn("Bad timestamp\n");
        }
    }
    else |_| {
        std.debug.warn("Bad epoch\n");
    }
    return 2;
}
