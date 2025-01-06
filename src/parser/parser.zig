const std = @import("std");
pub const Parser = struct {
    fn parse(pth: u8) !*Parser {
        std.debug.print("{s}\n", .{pth});
    }
};
