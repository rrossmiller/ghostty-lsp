const std = @import("std");
const structs = @import("structs.zig");

pub const LspError = error{MethodNotImplemented};
pub const MessageType = enum {
    //Requests
    Initialize,
    Hover,
    Completion,
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
        } else if (std.mem.eql(u8, method, "textDocument/completion")) {
            return MessageType.Completion;
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

    // skip lines to get to the current line
    for (0..params.position.line) |_| {
        _ = lines.next();
    }

    // work on the line
    if (lines.next()) |line| {
        var i = if (params.position.character > 0) params.position.character - 1 else 0;
        var start_idx: u32 = 0;
        var end_idx: u32 = 0;

        // if comment (#) is earlier in the line that hover location, don't hover
        if (line[0] == '#') {
            std.debug.print("line {d} has comment\n", .{params.position.line});
            return null;
        }
        //search backwards until space
        while (i > 0) : (i -= 1) {
            if (line[i] == ' ' or line[i] == '\t') {
                start_idx = i + 1;
                break;
            }
        }

        // if comment (#) is earlier in the line that hover location, don't hover
        while (i > 0) : (i -= 1) {
            if (line[i] == '#') {
                std.debug.print("line {d} has comment\n", .{params.position.line});
                return null;
            }
        }
        std.debug.print("{d}\n", .{params.position.line});

        //search forwards until space
        i = params.position.character + 1;
        while (i < line.len) : (i += 1) {
            end_idx = i;
            if (line[i] == ' ' or line[i] == '\t' or line[i] == '#') {
                break;
            }
        }

        const word = line[start_idx..end_idx];

        std.debug.print("get {s} docs\n", .{word});
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

pub fn completion(allocator: std.mem.Allocator, params: structs.CompletionParams) !?[]structs.CompletionItem {
    std.debug.print("completion for {s}\n", .{params.textDocument.uri});
    const items = try allocator.alloc(structs.CompletionItem, 1);
    // ask the static analysis tool to figure out good completions
    items[0] = .{
        .label = "LABEL",
        .detail = "DETAIL",
        .documentation = "DOCUMENTATION",
    };
    return items;
}

test "completion" {
    // const allocator = std.testing.allocator();
    const contents =
        \\this is line 1
        \\line2
        \\line3
        \\line4
    ;
    // const lines = try get_lines(contents);
    const params = structs.CompletionParams{
        .position = .{ .line = 0, .character = 10 },
        .textDocument = .{ .uri = "" },
    };

    completion(&params, contents);
    // std.testing.expectEqual(4, lines.len);
}
