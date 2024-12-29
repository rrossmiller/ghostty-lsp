const std = @import("std");

pub const Logger = struct {
    file: std.fs.File,
    allocator: std.mem.Allocator,
    pub fn init(fname: []const u8, allocator: std.mem.Allocator) !Logger {
        const log_file = try std.fs.cwd().createFile(
            fname,
            // "/Users/robrossmiller/Projects/ghostty-lsp/log.txt",
            .{ .read = true },
        );
        return Logger{ .file = log_file, .allocator = allocator };
    }

    pub fn deinit(self: *const Logger) void {
        self.file.close();
    }

    pub fn log(self: *const Logger, msg: []const u8) !void {
        const buf = try std.fmt.allocPrint(self.allocator, "{s}", .{msg});
        defer self.allocator.free(buf);
        try self.file.writeAll(buf);
    }
};
