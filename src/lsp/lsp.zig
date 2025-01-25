const std = @import("std");
const structs = @import("structs.zig");

pub const LspError = error{MethodNotImplemented};
pub const MessageType = enum {
    //Requests
    Initialize,
    Hover,
    //Notifications
    Initialized,
    DidOpen,
    DidChange,
    DidClose,
    DidSave,
    Shutdown,

    pub fn get(method: []const u8) LspError!MessageType {
        if (std.mem.eql(u8, method, "initialize")) {
            return MessageType.Initialize;
        } else if (std.mem.eql(u8, method, "textDocument/hover")) {
            return MessageType.Hover;
        } else if (std.mem.eql(u8, method, "initialized")) {
            return MessageType.Initialized;
        }
        //Notifications
        else if (std.mem.eql(u8, method, "textDocument/didOpen")) {
            return MessageType.DidOpen;
        } else if (std.mem.eql(u8, method, "textDocument/didChange")) {
            return MessageType.DidChange;
        } else if (std.mem.eql(u8, method, "textDocument/didClose")) {
            return MessageType.DidClose;
        } else if (std.mem.eql(u8, method, "textDocument/didSave")) {
            return MessageType.DidSave;
        } else if (std.mem.eql(u8, method, "shutdown")) {
            return MessageType.Shutdown;
        }
        std.debug.print(">>{s}<<\n", .{method});
        return LspError.MethodNotImplemented;
    }
};

pub fn hover(params: *const structs.HoverParams, contents: []const u8, docs_map: *const std.json.ArrayHashMap([]const u8)) ?[]const u8 {
    var lines = std.mem.split(u8, contents, "\n");

    // skip lines
    for (0..params.position.line) |_| {
        _ = lines.next();
    }

    if (lines.next()) |line| {
        var i = if (params.position.character > 0) params.position.character - 1 else 0;
        var start_idx: u32 = 0;
        var end_idx: u32 = 0;
        //search backwards until space
        while (i > 0) : (i -= 1) {
            if (line[i] == ' ' or line[i] == '\t') {
                start_idx = i + 1;
                break;
            }
        }
        //search forwards until space
        i = params.position.character + 1;
        while (i < line.len) : (i += 1) {
            if (line[i] == ' ' or line[i] == '\t') {
                end_idx = i;
                break;
            }
        }

        // std.debug.print("Hovered word: {s}\n", .{line[start_idx..end_idx]});
        // return line[start_idx..end_idx];
        const word = line[start_idx..end_idx];
        return docs_map.map.get(word);
    }
    return null;
}

test "hover" {
    // const allocator = std.testing.allocator();
    const contents =
        \\this is line 1
        \\line2
        \\line3
        \\line4
    ;
    // const lines = try get_lines(contents);
    const params = structs.HoverParams{
        .position = .{ .line = 0, .character = 10 },
        .textDocument = .{ .uri = "" },
    };

    hover(&params, contents);
    // std.testing.expectEqual(4, lines.len);
}
