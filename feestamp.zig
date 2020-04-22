const std = @import("std");
const feetime = @import("feetime.zig");
const fmt = std.fmt;
// This can't be re-imported or types won't match
const time = feetime.time;

pub fn main() !void {
    const stdout = try std.io.getStdOut();
    var instant: feetime.Time = undefined;
    if (std.os.argv.len < 2) {
        instant = feetime.currentTime();
    }
    else {
        var muggle: time.tm = undefined;
        const datetime = std.os.argv[1];
        var year: i32 = 0;
        var month: i32 = 0;
        var day: i32 = 0;
        var hour: i32 = 0;
        var minute: i32 = 0;
        var second: i32 = 0;

        // YY-mm-dd
        year = try fmt.parseInt(i32, datetime[0..4], 10);
        month = try fmt.parseInt(i32, datetime[5..7], 10);
        day = try fmt.parseInt(i32, datetime[8..10], 10);

        if (std.os.argv.len > 2) {
            const time_part = std.os.argv[2];
            hour = try fmt.parseInt(i32, time_part[0..2], 10);
            minute = try fmt.parseInt(i32, time_part[3..5], 10);
            second = try fmt.parseInt(i32, time_part[6..8], 10);
        }
        muggle = time.tm {
            .tm_year = year - 1900,
            .tm_mon = month - 1,
            .tm_mday = day,
            .tm_hour = hour,
            .tm_min = minute,
            .tm_sec = second,
            .tm_wday = 0,
            .tm_yday = 0,
            .tm_isdst = 0,
            .tm_gmtoff = 0,
            .tm_zone = 0,
        };
        instant = feetime.tmDecode(muggle);
    }

    const quarter = @intCast(u32, instant.quarter);
    var arrbuf = "xxxx.xxxx\n";
    _ = try std.fmt.bufPrint(arrbuf[0..],
            "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
            @truncate(u8, quarter), instant.week, instant.halfday,
            instant.hour, instant.tick, instant.sec);
    try stdout.write(arrbuf);
}
