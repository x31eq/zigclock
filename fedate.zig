const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return 1;
    }
    var stamp = "00000.00000";
    if (feetime.setStampFromArgs(stamp[0..])) {
        if (feetime.timeFromHex(stamp)) |instant| {
            var output_buffer = "YYYYY-mm-dd HH:MM:SS\n";
            try stdout.write(try instant.isoFormat(output_buffer[0..]));
            return 0;
        }
        else |_| {
            try stdout.write("Bad timestamp\n");
        }
    }
    else |_| {
        try stdout.write("Bad epoch\n");
    }
    return 2;
}
