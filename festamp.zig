const std = @import("std");
const time = @cImport(@cInclude("time.h"));
const stdio = @cImport(@cInclude("stdio.h"));

pub fn main() void {
    var local: time.tm = undefined;

    var timestamp = std.time.timestamp();
    _ = time.localtime_r(&@intCast(c_long, timestamp), &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    const quarter = @mod(year, 1024) * 4 + @divFloor(month, 3);
    var qday = @divFloor(month, 3);
    if (month == 2 or month == 11) {
        qday += 1;
    }
    const week = @divFloor(qday + local.tm_mday + 5 - local.tm_wday, 7);
    var halfday = local.tm_wday * 2;
    if (local.tm_hour > 11) {
        halfday += 1;
    }
    var ticks = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    ticks = @divFloor(ticks * 16,  15);
    _ = stdio.printf(c"%03x%01x.%01x%01x%02x\n",
        quarter, week, halfday, local.tm_hour, ticks);
}
