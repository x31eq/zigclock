const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    const stdout = try std.io.getStdOut();
    if (std.os.argv.len < 2) {
        try stdout.write("Supply the hex timestamp on the command line\n");
        return 1;
    }
    var stamp = "000000:0000";
    if(feetime.setStampFromArgs(stamp[0..])) {
        if (feetime.timeFromHex(stamp)) |instant| {
            try stdout.write(try instant.isoFormat());
            return 0;
        }
        else |_| {
            try stdout.write("Bad timestamp\n");
            return 2;
        }
    }
    else |_| {
        try stdout.write("Failed to read timestamp, probably a bad epoch\n");
        return 3;
    }
}
