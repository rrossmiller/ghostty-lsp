const std = @import("std");

pub const State = struct {
    allocator: std.mem.Allocator,
    // Map of file names to contents
    documents: std.StringHashMap([]const u8),
    pub fn init(allocator: std.mem.Allocator) State {
        return .{
            .allocator = allocator,
            .documents = std.StringHashMap([]const u8).init(allocator),
        };
    }
    pub fn deinit(self: *State) void {
        self.documents.deinit();
    }

    pub fn open_document(self: *State, uri: []const u8, text: []const u8) !void {
        try self.documents.put(uri, text);
    }
};
