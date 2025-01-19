const std = @import("std");

pub const Parser = struct {
    entries: std.StringHashMap([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !Parser {
        var parser = Parser{
            .entries = std.StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
        };

        // get reader over contents
        var content_stream = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(contents) };
        const content_reader = content_stream.reader();

        // loop over all lines
        const buf = try allocator.alloc(u8, 512);
        defer allocator.free(buf);
        // read every line
        while (try content_reader.readUntilDelimiterOrEof(buf, '\n')) |l| {
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
            try parser.parse_line(line);
            // break;
            std.debug.print("\n", .{});
        }
        if (parser.entries.getPtr("k")) |v| {
            std.debug.print(">>>>{s}\n", .{v.*});
        } else {
            std.debug.print(">>>>null\n", .{});
        }
        return parser;
    }

    fn consume_whitespace(line: []u8) []u8 {
        for (line, 0..) |b, i| {
            if (b != ' ' and b != '\t') {
                return line[i..];
            }
        }
        return line;
    }

    fn parse_line(self: *Parser, line: []u8) !void {
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
        const k = try self.allocator.dupe(u8, line[0..idx]);
        const v = try self.allocator.dupe(u8, line[val_start_idx..]);
        std.debug.print("Val: >{s}<\n", .{v});
        try self.entries.put(k, v);
    }

    pub fn deinit(self: *Parser) void {
        // Free all keys and values in the hash map
        var it = self.entries.iterator();
        while (it.next()) |e| {
            self.allocator.free(e.key_ptr.*);
            self.allocator.free(e.value_ptr.*);
        }
        self.entries.deinit();
    }
};

test "init parser" {
    const allocator = std.testing.allocator;
    const contents =
        \\ k=v
        \\  # font-family = "JetBrains Mono"
        \\      # font-family = "JetBrains Mono"
        \\# font-family = "JetBrains Mono"
        \\font-family = "Hack Nerd Font Mono"
        \\font-thicken= true
    ;
    var p = try Parser.init(allocator, contents);
    defer p.deinit();
    var v = p.entries.get("k").?;
    try std.testing.expectEqualStrings("v", v);

    v = p.entries.get("font-family").?;
    try std.testing.expectEqualStrings("\"Hack Nerd Font Mono\"", v);
    v = p.entries.get("font-thicken").?;
    try std.testing.expectEqualStrings("true", v);
}
