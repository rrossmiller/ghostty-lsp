const std = @import("std");
const structs = @import("structs.zig");
const State = @import("../analysis/state.zig").State;

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
