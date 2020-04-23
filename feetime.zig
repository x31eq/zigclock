const std = @import("std");
const fmt = std.fmt;
const os = std.os;
const time = @cImport(@cInclude("time.h"));

pub const Time = packed struct {
    quarter: i24,
    week: u8,
    halfday: u8,
    hour: u8,
    tick: u8,
    sec: u8,
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
fn weekday(year: i32, month: i32, day: i32) u8 {
    // Based on RFC 3339 Appendix B
    var Y = year;

    var m = month - 1;
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

    muggle = time.tm {
        .tm_year = 84,
        .tm_mon = 0,
        .tm_mday = 0,
        .tm_wday = 0,
        .tm_hour = 0,
        .tm_min = 0,
        .tm_sec = 0,
        .tm_yday = 0,
        .tm_isdst = 0,
        .tm_gmtoff = 0,
        .tm_zone = 0,
    };

    if (datetime[0] == '@') {
        // POSIX timestamp (in decimal)
        const timeslice = datetime[1..std.mem.len(u8, datetime)];
        const timestamp = try fmt.parseInt(i64, timeslice, 10);
        _ = time.localtime_r(&@intCast(c_long, timestamp), &muggle);
        return tmDecode(muggle);
    }

    if (datetime[2] == ':') {
        // HH:MM:SS
        try parseTime(datetime[0..std.mem.len(u8, datetime)], &muggle);
    }
    else {
        // YY-mm-dd
        try parseDate(datetime[0..10], &muggle);
        if (std.os.argv.len > 2) {
            // HH:MM:SS
            const time_part = std.os.argv[2];
            try parseTime(time_part[0..std.mem.len(u8, time_part)], &muggle);
        }
        else if (datetime[10] == ' ') {
            // HH:MM:SS further back
            try parseTime(datetime[11..19], &muggle);
        }
    }
    const wday = weekday(muggle.tm_year + 1900, muggle.tm_mon, muggle.tm_mday);
    muggle.tm_wday = @intCast(i32, wday);
    return tmDecode(muggle);
}

/// Turn a YYYY-mm-dd string into years, months, and days
fn parseDate(date_part: []u8, muggle: *time.struct_tm) !void {
    muggle.tm_year = (try fmt.parseInt(i32, date_part[0..4], 10)) - 1900;
    muggle.tm_mon = (try fmt.parseInt(i32, date_part[5..7], 10)) - 1;
    muggle.tm_mday = try fmt.parseInt(i32, date_part[8..], 10);
}

/// Turn a HH:MM:SS string into hours, minutes and seconds
fn parseTime(time_part: []u8, muggle: *time.struct_tm) !void {
    muggle.tm_hour = try fmt.parseInt(i32, time_part[0..2], 10);
    muggle.tm_min = try fmt.parseInt(i32, time_part[3..5], 10);
    muggle.tm_sec = try fmt.parseInt(i32, time_part[6..], 10);
}
