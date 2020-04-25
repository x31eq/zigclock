const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const feetime = @import("feetime.zig");
// This can't be imported directly from the header or typing breaks
const time = feetime.time;

pub fn main() !u8 {
    var arrbuf = "xxxx:xxxx\n";
    return mainDelegated(formatHex, arrbuf[0..]);
}

pub fn formatHex(instant: feetime.Time, buffer: []u8) !void {
    const quarter = @intCast(u32, instant.quarter);
    _ = try fmt.bufPrint(buffer,
                "{x:0>2}{x:0>1}{x:0>1}:{x:0>1}{x:0>2}{x:0>1}",
                @truncate(u8, quarter), instant.week, instant.halfday,
                instant.hour, instant.tick, instant.sec);
}

pub fn mainDelegated(formatter: @typeOf(formatHex), arrbuf: []u8) !u8 {
    const stdout = try std.io.getStdOut();

    if (timeFromArgs()) |instant| {
        if (formatter(instant, arrbuf)) |_| {
            if (std.mem.endsWith(u8, arrbuf, "\n")) {
                try stdout.write(arrbuf);
                return 0;
            }
            else {
                // This means the format overran
                std.debug.warn("Invalid date/time\n");
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

/// Determine a time from command line arguments.
pub fn timeFromArgs() !feetime.Time {
    if (std.os.argv.len < 2) {
        return feetime.currentTime();
    }
    var muggle: time.tm = undefined;
    const datetime = std.os.argv[1];

    muggle = time.tm {
        .tm_year = 84,
        .tm_mon = 0,
        .tm_mday = 1,
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
        const timeslice = datetime[1..mem.len(u8, datetime)];
        const timestamp = try fmt.parseInt(i64, timeslice, 10);
        _ = time.localtime_r(&@intCast(c_long, timestamp), &muggle);
        return feetime.tmDecode(muggle);
    }

    const datetime_slice = datetime[0..mem.len(u8, datetime)];
    if (mem.indexOfAny(u8, datetime_slice, " T")) |space| {
        // YY-mm-dd HH:MM:SS as a single argument
        try parseDate(datetime[0..space], &muggle);
        try parseTime(datetime_slice[(space + 1)..], &muggle);
    }
    else if (mem.indexOfScalar(u8, datetime_slice, ':') == null) {
        // YY-mm-dd
        try parseDate(datetime_slice, &muggle);

        if (std.os.argv.len > 2) {
            // HH:MM:SS
            const time_part = std.os.argv[2];
            const time_slice = time_part[0..mem.len(u8, time_part)];
            try parseTime(time_slice, &muggle);
        }
    }
    else {
        // HH:MM:SS
        try parseTime(datetime_slice, &muggle);
    }
    const wday = feetime.weekday(
            muggle.tm_year + 1900, muggle.tm_mon, muggle.tm_mday);
    muggle.tm_wday = @intCast(i32, wday);
    return feetime.tmDecode(muggle);
}

/// Turn a YYYY-mm-dd string into years, months, and days
fn parseDate(date_part: []u8, muggle: *time.struct_tm) !void {
    var tokens = mem.tokenize(date_part, "-");
    muggle.tm_year = (try fmt.parseInt(i32, tokens.next().?, 10)) - 1900;
    muggle.tm_mon = (try fmt.parseInt(i32, tokens.next().?, 10)) - 1;
    muggle.tm_mday = try fmt.parseInt(i32, tokens.next().?, 10);
}

/// Turn a HH:MM:SS string into hours, minutes and seconds
fn parseTime(time_part: []u8, muggle: *time.struct_tm) !void {
    var tokens = mem.tokenize(time_part, ":");
    muggle.tm_hour = try fmt.parseInt(i32, tokens.next().?, 10);
    muggle.tm_min = try fmt.parseInt(i32, tokens.next().?, 10);
    muggle.tm_sec = try fmt.parseInt(i32, (tokens.next() orelse "0"), 10);
}
