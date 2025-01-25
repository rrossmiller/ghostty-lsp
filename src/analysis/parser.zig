const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, contents: []const u8, entries: *std.StringHashMap([]const u8)) !void {
    //     TODO handle  keybind --> keybinds should not be overwritten
    //     use a union of either string or keybind struct?
    // keybind = global:opt+space=toggle_quick_terminal
    // keybind = cmd+shift+l=move_tab:+1
    // keybind = cmd+shift+h=move_tab:-1
    // get reader over contents
    var content_stream = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(contents) };
    const content_reader = content_stream.reader();

    // loop over all lines
    const buf = try allocator.alloc(u8, 256); // buffer to hold the line
    defer allocator.free(buf);
    // read every line
    while (try content_reader.readUntilDelimiterOrEof(buf, '\n')) |l| {
        if (l.len == 0) {
            continue;
        }
        std.debug.print("before: >{s}<\n", .{l});
        const line = consume_whitespace(l);
        std.debug.print("rm whitespace: >{s}<\n", .{line});

        // skip commented out lines
        if ('#' == line[0]) {
            std.debug.print("comment: >{s}<\n\n", .{line});
            continue;
        }
        std.debug.print("no comment: >{s}<\n", .{line});

        // parse the line
        try parse_line(allocator, line, entries);
        std.debug.print("\n", .{});
    }
}

fn consume_whitespace(line: []u8) []u8 {
    for (line, 0..) |b, i| {
        if (b != ' ' and b != '\t') {
            return line[i..];
        }
    }
    return line;
}

fn parse_line(allocator: std.mem.Allocator, line: []u8, entries: *std.StringHashMap([]const u8)) !void {
    // get the key
    var idx: usize = 0;
    for (line, 0..) |b, i| {
        if (b == ' ' or b == '=') {
            idx = i;
            break;
        }
    }
    std.debug.print("ID: {s}\n", .{line[0..idx]});
    // get the value
    var val_start_idx: usize = 0;
    for (line[idx..], idx..) |b, i| {
        // consume the equals
        if (b != ' ' and b != '=') {
            val_start_idx = i;
            break;
        }
    }
    const k = try allocator.dupe(u8, line[0..idx]);
    const v = try allocator.dupe(u8, line[val_start_idx..]);
    std.debug.print("Val: >{s}<\n", .{v});
    try entries.put(k, v);
}

test "parse" {
    const allocator = std.testing.allocator;
    const contents =
        \\ k=v
        \\  # font-family = "JetBrains Mono"
        \\      # font-family = "JetBrains Mono"
        \\# font-family = "JetBrains Mono"
        \\font-family = "Hack Nerd Font Mono"
        \\
        \\          #
        \\font-thicken= true
    ;
    // var p = State.init(allocator);
    var entries = std.StringHashMap([]const u8).init(allocator);
    defer {
        var entry_it = entries.iterator();
        while (entry_it.next()) |e| {
            allocator.free(e.key_ptr.*);
            allocator.free(e.value_ptr.*);
        }
        entries.deinit();
    }

    try parse(allocator, contents, &entries);
    var v = entries.get("k").?;
    try std.testing.expectEqualStrings("v", v);

    v = entries.get("font-family").?;
    try std.testing.expectEqualStrings("\"Hack Nerd Font Mono\"", v);
    v = entries.get("font-thicken").?;
    try std.testing.expectEqualStrings("true", v);
}
