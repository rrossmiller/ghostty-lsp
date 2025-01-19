const std = @import("std");

pub const State = struct {
    allocator: std.mem.Allocator,
    documents: std.StringHashMap([]const u8),
    entries: std.StringHashMap([]const u8),
    pub fn init(allocator: std.mem.Allocator) State {
        return .{
            .allocator = allocator,
            .documents = std.StringHashMap([]const u8).init(allocator),
            .entries = undefined,
        };
    }
    pub fn deinit(self: *State) void {
        var it = self.documents.iterator();
        while (it.next()) |e| {
            self.allocator.free(e.key_ptr.*);
            self.allocator.free(e.value_ptr.*);
        }
        self.documents.deinit();
    }

    pub fn open_document(self: *State, uri: []const u8, text: []const u8) !void {
        //TODO parse the text

        // need to reallocate key and text because it will be freed when the params obj is freed
        const my_txt = try self.documents.allocator.dupe(u8, text);
        const my_uri = try self.allocator.dupe(u8, uri);
        try self.documents.put(my_uri, my_txt);
    }
    pub fn update_document(self: *State, uri: []const u8, text: []const u8) !void {
        const my_txt = try self.allocator.dupe(u8, text);
        if (try self.documents.fetchPut(uri, my_txt)) |kv| {
            self.allocator.free(kv.value);
        }
    }
    pub fn remove_doc(self: *State, uri: []const u8) void {
        if (self.documents.fetchRemove(uri)) |kv| {
            self.allocator.free(kv.key);
            self.allocator.free(kv.value);
        }
    }
};
