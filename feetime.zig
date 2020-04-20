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
    var sec = @intCast(u16, local.tm_sec);
    var tick = sec / 15 - sec / 60;
    sec -= tick * 15;
    tick += @intCast(u16, local.tm_min) * 4;
    return Time {
        .quarter = year * 4 + @divFloor(month, 3),
        .week = @truncate(u8, qday / 7),
        .halfday = @intCast(u8, local.tm_wday * 2)
                    + @boolToInt(local.tm_hour > 11),
        .hour = @intCast(u8, local.tm_hour) % 12,
        .tick = @truncate(u8, (tick * 16) / 15),
        .sec = @truncate(u8, sec),
    };
}

const MuggleTime = packed struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    min: u8,
    sec: u8,
};

pub fn decode(feetime: Time) MuggleTime {
    const year = 1920 + @mod(@divFloor(feetime.quarter, 4) + 128, 1024);
    const month = (@intCast(u8, feetime.quarter) % 4) * 3
                    + feetime.week / 0x55;
    var k = (month % 3) * 38 + 5;
    if (month ==  2 or month == 11) {
        k -= 1;
    }
    const day = feetime.week * 7 + feetime.halfday / 2
            + (1 + k - month_weekday(year, month)) % 7 - k;
    const toc = feetime.tick / 16 * 15 + feetime.tick % 16;
    return MuggleTime {
        .year = year,
        .month = month + 1,
        .day = day,
        .hour = feetime.hour + 12 * (feetime.halfday & 1),
        .min = toc / 4,
        .sec = (toc % 4) * 15 + feetime.sec,
    };
}

/// Weekday (Sunday is 0) of the first day of the month
/// month is 0 for January
fn month_weekday(year: i32, month: u8) u8 {
    std.debug.warn("Getting first day of week for {}-{}\n",
                    year, month + 1);
    // Based on RFC 3339 Appendix B
    var Y = year;

    var m = @intCast(i32, month) - 1;
    if (m < 1) {
        m += 12;
        Y -= 1;
    }
    const cent = @divFloor(Y, 100);
    Y = @mod(Y, 100);

    const day = @divFloor(26 * m - 2, 10) + 1 + Y
                + @divFloor(Y, 4) + @divFloor(cent, 4) + 5 * cent;
    std.debug.warn("Month started on {}\n", @mod(day, 7));
    return @intCast(u8, @mod(day, 7));
}
