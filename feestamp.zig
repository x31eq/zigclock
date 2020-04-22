const std = @import("std");
const feetime = @import("feetime.zig");

const time = @cImport({
    @cDefine("_X_OPEN_SOURCE", "");
    @cInclude("time.h");
});

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    var instant: feetime.Time = undefined;
    if (std.os.argv.len < 2) {
        instant = feetime.currentTime();
    }
    else {
        var muggle: time.tm = undefined;
        if (!time.strptime(std.os.argv[1], "%Y-%m-%d %T", &muggle)) {
            stdout.write("Specify timestamp as YYYY-mm-dd HH:MM:SS\n");
            return;
        }
        instant = feetime.decode_tm(muggle);
    }

    const quarter = @intCast(u32, instant.quarter);
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
            @truncate(u8, quarter), instant.week, instant.halfday,
            instant.hour, instant.tick, instant.sec);
    try stdout.write(arrbuf);
}
