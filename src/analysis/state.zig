const std = @import("std");

// I can't figure out string hashmaps with string values
pub const State =
    struct {
    uri: []const u8 = "",
    text: []const u8 = "",
    pub fn open_document(self: *State, uri: []const u8, text: []const u8) void {
        //TODO parse the text
        self.uri = uri;
        self.text = text;
    }
    pub fn update_document(self: *State, text: []const u8) void {
        self.text = text;
    }
};
// std.StringHashMap([]const u8);
//     struct {
//     // Map of file names to contents
//     keys: std.StringHashMap(usize),
//     values: std.ArrayList([]const u8),
//     pub fn init(allocator: std.mem.Allocator) State {
//         return .{
//             .keys = std.StringHashMap(usize).init(allocator),
//             .values = std.ArrayList([]const u8).init(allocator),
//         };
//     }
//     pub fn deinit(self: *State) void {
//         self.keys.deinit();
//         self.values.deinit();
//     }
//
//     pub fn get(self: *State, uri: []const u8) ?[]const u8 {
//         // if the idx exists, return the value in the arraylist
//         if (self.keys.get(uri)) |idx| {
//             return self.values.items[idx];
//         }
//         return null;
//     }
//
//     pub fn open_document(self: *State, uri: []const u8, text: []const u8) !void {
//         //TODO parse the text
//         try self.keys.put(uri, self.values.items.len);
//         try self.values.append(text);
//     }
//     pub fn update_document(self: *State, uri: []const u8, text: []const u8) void {
//         if (self.keys.get(uri)) |idx| {
//             self.values.items[idx] = text;
//         }
//     }
// };
