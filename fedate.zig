const feedate = @import("feedate.zig");

pub fn main() !u8 {
    return feedate.main_delegated("00000.00000"[0..]);
}
