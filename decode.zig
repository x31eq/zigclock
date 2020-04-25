const std = @import("std");

pub fn main() !u8 {
    if (std.os.argv.len < 2) {
        std.debug.warn("Supply the hex timestamp on the command line\n");
        return 1;
    }
    const stamp_arg = std.os.argv[1];
    const stamp_in = stamp_arg[0..std.mem.len(u8, stamp_arg)];
    if (std.mem.indexOfScalar(u8, stamp_in, ':') == null) {
        return try @import("fedate.zig").main();
    }
    return try @import("feedate.zig").main();
}
