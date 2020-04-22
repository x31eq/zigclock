const std = @import("std");
const fmt = std.fmt;
const os = std.os;
const time = @cImport(@cInclude("time.h"));
const strlen = @cImport(@cInclude("string.h")).strlen;

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
    return tmDecode(local);
}

fn tmDecode(muggle: time.tm) Time {
    const year = muggle.tm_year + 1900;
    const month = muggle.tm_mon;
    // Guess the first day of the month of the quarter by
    // counting days in previous months assuming 31 days per month.
    var qday = @intCast(u16, month) % 3 * 38;
    // Correct for February and November not having 31 days.
    // This is good enough to keep months distinct.
    if (month == 2 or month == 11) {
        qday -= 1;
    }
    const wday = @intCast(i32,
            weekday(year, @intCast(u8, month), muggle.tm_mday));
    // Now add extra days to account for months not starting on Sunday.
    qday += @intCast(u16, muggle.tm_mday + 5 - muggle.tm_wday);
    var sec = @intCast(u16, muggle.tm_sec);
    var tick = sec / 15 - sec / 60;
    sec -= tick * 15;
    tick += @intCast(u16, muggle.tm_min) * 4;
    return Time {
        .quarter = @intCast(i24, year * 4 + @divFloor(month, 3)),
        .week = @truncate(u8, qday / 7),
        .halfday = @intCast(u8, muggle.tm_wday * 2)
                    + @boolToInt(muggle.tm_hour > 11),
        .hour = @intCast(u8, muggle.tm_hour) % 12,
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

pub fn decode(feetime: Time) time.tm {
    const year = @divFloor(feetime.quarter, 4);
    const month = (@intCast(u8, feetime.quarter) % 4) * 3
                    + (feetime.week * 16 + feetime.halfday) / 0x55;
    // Guess for first day of the month of the quarter.
    // Compare with code in the "to hex" calculation.
    var qday = (month % 3) * 38;
    if (month == 2 or month == 11) {
        qday -= 1;
    }
    const wday = weekday(year, month, 1);
    // week = (qday + day + 5 - weekday) / 7    [1]
    // weekday = (weekday_1 + day - 1) % 7      [2]
    // qday as above
    // day = day of month (first day = 1) (we want to find this)
    // weekday = days since Sunday
    // wday = days since Sunday for the first day of the month (as above)
    //
    // Rearrange [1]
    // week * 7 = qday + day + 5 - weekday
    //            - (qday + day + 5 - weekday) % 7
    // day = week * 7 + weekday - qday - 5
    //       + (qday + day + 5 - weekday) % 7
    //
    // Substitute in [2]
    // day = week * 7 + weekday - qday - 5
    //       + (qday + day + 5 - (wday + day - 1)) % 7
    // day = week * 7 + weekday - qday - 5 - (qday + 6 - wday) % 7
    const day = feetime.week * 7 +% feetime.halfday / 2 -% qday -% 5
            +% (6 + qday - wday) % 7;
    const toc = feetime.tick / 16 * 15 + feetime.tick % 16;
    return time.tm {
        .tm_year = year - 1900,
        .tm_mon = month,
        .tm_mday = day,
        .tm_wday = wday,
        .tm_hour = feetime.hour + 12 * (feetime.halfday & 1),
        .tm_min = toc / 4,
        .tm_sec = (toc % 4) * 15 + feetime.sec,
        .tm_yday = 0,
        .tm_isdst = 0,
        .tm_gmtoff = 0,
        .tm_zone = 0,
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

/// Determine a time from command line arguments.
/// This isn't very generic, but saves a lot of duplicated code.
pub fn timeFromArgs() !Time {
    if (std.os.argv.len < 2) {
        return currentTime();
    }
    var muggle: time.tm = undefined;
    const datetime = std.os.argv[1];

    if (datetime[0] == '@') {
        // POSIX timestamp (in decimal)
        const timeslice = datetime[1..strlen(datetime)];
        const timestamp = try fmt.parseInt(i64, timeslice, 10);
        var local: time.tm = undefined;
        _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
        return tmDecode(local);
    }

    var year: i32 = 0;
    var month: i32 = 1;
    var day: i32 = 0;
    var hour: i32 = 0;
    var minute: i32 = 0;
    var second: i32 = 0;

    if (datetime[2] == ':') {
        // HH:MM:SS
        hour = try fmt.parseInt(i32, datetime[0..2], 10);
        minute = try fmt.parseInt(i32, datetime[3..5], 10);
        second = try fmt.parseInt(i32, datetime[6..8], 10);
    }
    else {
        // YY-mm-dd
        year = try fmt.parseInt(i32, datetime[0..4], 10);
        month = try fmt.parseInt(i32, datetime[5..7], 10);
        day = try fmt.parseInt(i32, datetime[8..10], 10);

        if (std.os.argv.len > 2) {
            // HH:MM:SS
            const time_part = std.os.argv[2];
            hour = try fmt.parseInt(i32, time_part[0..2], 10);
            minute = try fmt.parseInt(i32, time_part[3..5], 10);
            second = try fmt.parseInt(i32, time_part[6..8], 10);
        }
        else if (datetime[10] == ' ') {
            // HH:MM:SS further back
            hour = try fmt.parseInt(i32, datetime[11..13], 10);
            minute = try fmt.parseInt(i32, datetime[14..16], 10);
            second = try fmt.parseInt(i32, datetime[17..19], 10);
        }
    }

    muggle = time.tm {
        .tm_year = year - 1900,
        .tm_mon = month - 1,
        .tm_mday = day,
        .tm_hour = hour,
        .tm_min = minute,
        .tm_sec = second,
        .tm_wday = @intCast(i32, weekday(year, @intCast(u8, month - 1), day)),
        .tm_yday = 0,
        .tm_isdst = 0,
        .tm_gmtoff = 0,
        .tm_zone = 0,
    };
    return tmDecode(muggle);
}
