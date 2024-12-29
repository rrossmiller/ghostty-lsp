const std = @import("std");
const ctime = @cImport({
    @cInclude("time.h");
});

pub const Logger = struct {
    file: std.fs.File,
    allocator: std.mem.Allocator,
    pub fn init(fname: []const u8, allocator: std.mem.Allocator) !Logger {
        const log_file = try std.fs.cwd().createFile(
            fname,
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
    fn get_time() []u8 {
        var now: ctime.time_t = undefined;
        _ = ctime.time(&now);
        const timeinfo = ctime.localtime(&now);
        const s = ctime.asctime(timeinfo);
        std.debug.print("{s}\n", .{s});
        return "";
    }
};
