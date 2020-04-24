const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    const stdout = try std.io.getStdOut();

    if (feetime.timeFromArgs()) |instant| {
        const quarter = @intCast(u32, instant.quarter);
        var arrbuf = "xxxx:xxxx\n";
        if (std.fmt.bufPrint(arrbuf[0..],
                "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
                @truncate(u8, quarter), instant.week, instant.halfday,
                instant.hour, instant.tick, instant.sec)) |_| {
            if (std.mem.endsWith(u8, arrbuf, "\n")) {
                try stdout.write(arrbuf);
                return 0;
            }
            else {
                // This means the format overran
                try stdout.write("Invalid date/time\n");
                return 1;
            }
        }
        else |_| {
            try stdout.write("Failed to encode\n");
            return 2;
        }
    }
    else |_| {
        try stdout.write("Bad date/time format\n");
        return 3;
    }
}
