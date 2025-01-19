const std = @import("std");

pub const Parser = struct {
    entries: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !Parser {
        const parser = Parser{
            .entries = std.StringHashMap([]const u8).init(allocator),
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
            const res = eat_whitespace(l);
            std.debug.print("rm whitespace: >{s}<\n", .{res});

            // skip commented out lines
            if ('#' == res[0]) {
                std.debug.print("comment: >{s}<\n", .{res});
            } else {
                std.debug.print("no comment: >{s}<\n", .{res});
            }

            // parse the line
            // break;
            std.debug.print("\n", .{});
        }

        return parser;
    }

    // fn eat_whitespace(allocator: std.mem.Allocator, reader: std.io.StreamSource.Reader) ![]u8 {
    fn eat_whitespace(line: []u8) []u8 {
        for (line, 0..) |b, i| {
            if (b != ' ' and b != '\t') {
                return line[i..];
            }
        }
        return line;
    }

    pub fn deinit(self: *Parser) void {
        self.entries.deinit();
    }
};

test "init parser" {
    const allocator = std.testing.allocator;
    const contents =
        \\  # font-family = "JetBrains Mono"
        \\      # font-family = "JetBrains Mono"
        \\# font-family = "JetBrains Mono"
        \\font-family = "Hack Nerd Font Mono"
        \\font-thicken = true
    ;
    _ = try Parser.init(allocator, contents);
}
