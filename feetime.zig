const std = @import("std");
const os = std.os;
const time = @cImport(@cInclude("time.h"));

pub const Time = packed struct {
    quarter: i24,
    week: u8,
    halfday: u8,
    hour: u8,
    tick: u8,
    sec: u8 = 0,
};

pub fn currentTime() Time {
    var local: time.tm = undefined;
    var ts: os.timespec = undefined;

    os.clock_gettime(os.CLOCK_REALTIME, &ts) catch unreachable;
    var timestamp = ts.tv_sec;
    _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    // Guess the first day of the month of the quarter by
    // counting days in previous months assuming 31 days per month.
    var qday = @intCast(u16, month) % 3 * 38;
    // Correct for February and November not having 31 days.
    // This is good enough to keep months distinct.
    if (month == 2 or month == 11) {
        qday -= 1;
    }
    // Now add extra days to account for months not starting on Sunday.
    qday += @intCast(u16, local.tm_mday + 5 - local.tm_wday);
    var sec = @intCast(u16, local.tm_sec);
    var tick = sec / 15 - sec / 60;
    sec -= tick * 15;
    tick += @intCast(u16, local.tm_min) * 4;
    return Time {
        .quarter = @intCast(i24, year * 4 + @divFloor(month, 3)),
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
    const year = @divFloor(feetime.quarter, 4);
    const month = (@intCast(u8, feetime.quarter) % 4) * 3
                    + (feetime.week * 16 + feetime.halfday) / 0x55;
    // Guess for first day of the month of the quarter.
    // Compare with code in the "to hex" calculation.
    var qday = (month % 3) * 38;
    if (month == 2 or month == 11) {
        qday -= 1;
    }
    // week = (qday + day + 5 - weekday) / 7    [1]
    // weekday = (weekday_1 + day - 1) % 7      [2]
    // qday as above
    // day = day of month (first day = 1) (we want to find this)
    // weekday = days since Sunday
    // weekday_1 = days since Sunday for the first day of the month
    //
    // Rearrange [1]
    // week * 7 = qday + day + 5 - weekday
    //            - (qday + day + 5 - weekday) % 7
    // day = week * 7 + weekday - qday - 5
    //       + (qday + day + 5 - weekday) % 7
    //
    // Substitute in [2]
    // day = week * 7 + weekday - qday - 5
    //       + (qday + day + 5 - (weekday_1 + day - 1)) % 7
    // day = week * 7 + weekday - qday - 5 - (qday + 6 - weekday_1) % 7
    const day = feetime.week * 7 +% feetime.halfday / 2 -% qday -% 5
            +% (6 + qday - weekday(year, month, 1)) % 7;
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

/// Weekday (Sunday is 0) of a given day
/// Where day starts at 1 and month is 0 for January
fn weekday(year: i32, month: u8, day: i32) u8 {
    // Based on RFC 3339 Appendix B
    var Y = year;

    var m = @intCast(i32, month) - 1;
    if (m < 1) {
        m += 12;
        Y -= 1;
    }
    const cent = @divFloor(Y, 100);
    Y = @mod(Y, 100);

    const wday = @divFloor(26 * m - 2, 10) + day + Y
                + @divFloor(Y, 4) + @divFloor(cent, 4) + 5 * cent;
    return @intCast(u8, @mod(wday, 7));
}
