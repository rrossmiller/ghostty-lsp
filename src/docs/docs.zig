const std = @import("std");
const doc_str = @import("doc_text.zig").doc_str;

pub fn read_docs(allocator: std.mem.Allocator) !std.json.Parsed(std.json.ArrayHashMap([]const u8)) {
    const parsed = try std.json.parseFromSlice(std.json.ArrayHashMap([]const u8), allocator, doc_str, .{ .ignore_unknown_fields = true });
    return parsed;
}

test "read docs" {
    const allocator = std.testing.allocator;
    const parsed = try read_docs(allocator);
    defer parsed.deinit();
    const docs_map = parsed.value;
    const t =
        \\String to send when we receive `ENQ` (`0x05`) from the command that we are
        \\running. Defaults to an empty string if not set.
    ;
    try std.testing.expectEqualStrings(t, docs_map.map.get("enquiry-response").?);
}
