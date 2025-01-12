const std = @import("std");
const structs = @import("structs.zig");
const State = @import("../analysis/state.zig").State;

pub const LspError = error{MethodNotImplemented};
pub const MessageType = enum {
    Initialize,
    Initialized,
    DidOpen,
    DidChange,
    DidClose,
    DidSave,
    Shutdown,

    pub fn get(method: []const u8) LspError!MessageType {
        if (std.mem.eql(u8, method, "initialize")) {
            return MessageType.Initialize;
        } else if (std.mem.eql(u8, method, "initialized")) {
            return MessageType.Initialized;
        } else if (std.mem.eql(u8, method, "textDocument/didOpen")) {
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
        return LspError.MethodNotImplemented;
    }
};
pub fn handle_changes(params: structs.DidChangeParams, state: *State) !void {
    std.debug.print("Handling changes\n", .{});
    for (params.contentChanges) |change| {
        try state.update_document(params.textDocument.uri, change.text);
    }
}
