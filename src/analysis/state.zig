const std = @import("std");

// I can't figure out string hashmaps with string values
pub const State =
    struct {
    allocator: std.mem.Allocator,
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
        //TODO parse the text
        // try self.keys.put(uri, self.values.items.len);
        // try self.values.append(text);
        const my_uri = try self.documents.allocator.dupe(u8, uri);
        const my_txt = try self.documents.allocator.dupe(u8, text);
        try self.documents.put(my_uri, my_txt);
    }
    pub fn update_document(self: *State, uri: []const u8, text: []const u8) !void {
        todo fetch put
        free value
        try self.open_document(uri, text);
    }
};
