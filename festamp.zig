const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("time.h");
});

pub fn main() void {
    var timestamp: c.timespec = undefined;
    var local: c.tm = undefined;
    _ = c.clock_gettime(c.CLOCK_REALTIME, &timestamp);
    _ = c.localtime_r(&timestamp.tv_sec, &local);
    const year = local.tm_year + 1900;
    const month = local.tm_mon;
    const quarter = @mod(year, 1024) * 4 + @divFloor(month, 3);
    var qday = @divFloor(month, 3);
    if (month == 2 or month == 11) {
      qday += 1;
    }
    const week = @divFloor(qday + local.tm_mday + 5 - local.tm_wday, 7);
    _ = c.printf(c"%03x%01x", quarter, week);
    var halfday = local.tm_wday * 2;
    if (local.tm_hour > 11) {
        halfday += 1;
    }
    var ticks = (local.tm_min * 4 + @divFloor(local.tm_sec, 15));
    ticks = @divFloor(ticks * 16,  15);
    _ = c.printf(c".%01x%01x%01x\n", halfday, local.tm_hour, ticks);
}
