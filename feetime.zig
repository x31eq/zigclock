const std = @import("std");
const time = @cImport(@cInclude("time.h"));

const Time = packed struct {
    quarter: i32,
    week: u8,
    halfday: u8,
    hour: u8,
    tick: u8,
    sec: u8,
};

pub fn currentTime() Time {
    var local: time.tm = undefined;

    var timestamp = std.time.timestamp();
    _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    var qday = @intCast(u16, month) / 3;
    if (month == 2 or month == 11) {
        qday += 1;
    }
    qday += @intCast(u16, local.tm_mday + 5 - local.tm_wday);
    var tick = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    return Time {
        .quarter = year * 4 + @divFloor(month, 3),
        .week = @truncate(u8, qday / 7),
        .halfday = @intCast(u8, local.tm_wday * 2)
                    + @boolToInt(local.tm_hour > 11),
        .hour = @intCast(u8, local.tm_hour) % 12,
        .tick = @truncate(u8, @intCast(u32, tick * 16) / 15),
        .sec = @intCast(u8, local.tm_sec) % 15,
    };
}
