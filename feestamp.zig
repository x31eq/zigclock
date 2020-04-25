const std = @import("std");
const feetime = @import("feetime.zig");

pub fn main() !u8 {
    var arrbuf = "xxxx:xxxx\n";
    return mainDelegated(formatHex, arrbuf[0..]);
}

pub fn formatHex(instant: feetime.Time, buffer: []u8) !void {
    const quarter = @intCast(u32, instant.quarter);
    _ = try std.fmt.bufPrint(buffer,
                "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
                @truncate(u8, quarter), instant.week, instant.halfday,
                instant.hour, instant.tick, instant.sec);
}

pub fn mainDelegated(formatter: @typeOf(formatHex), arrbuf: []u8) !u8 {
    const stdout = try std.io.getStdOut();

    if (feetime.timeFromArgs()) |instant| {
        if (formatter(instant, arrbuf)) |_| {
            if (std.mem.endsWith(u8, arrbuf, "\n")) {
                try stdout.write(arrbuf);
                return 0;
            }
            else {
                // This means the format overran
                std.debug.warn("Invalid date/time {}\n");
                return 1;
            }
        }
        else |_| {
            std.debug.warn("Failed to encode\n");
            return 2;
        }
    }
    else |_| {
        try stdout.write("Bad date/time format\n");
        return 3;
    }
}
