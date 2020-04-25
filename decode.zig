const std = @import("std");
const feedate = @import("feedate.zig");

pub fn main() !u8 {
    if (std.os.argv.len < 2) {
        std.debug.warn("Supply the hex timestamp on the command line\n");
        return 1;
    }
    const stamp_arg = std.os.argv[1];
    const stamp_in = stamp_arg[0..std.mem.len(u8, stamp_arg)];
    if (std.mem.indexOfScalar(u8, stamp_in, ':') == null) {
        return try feedate.main_delegated("000000:0000");
    }
    return try feedate.main_delegated("00000.00000");
}
