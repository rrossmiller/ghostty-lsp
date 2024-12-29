pub fn ResponseMessage(comptime _: type) type {
    return struct {
        jsonrpc: []const u8 = "2.0",
        id: ?u32 = null,
        //result
    };
}

pub fn Notification(comptime _: type) type {
    return struct {
        jsonrpc: []const u8 = "2.0",
        method: []const u8,

        //params
    };
}

pub const InitializeParams = struct {
    //
};
pub fn newInitializeResponse() *const [193:0]u8 {
    return 
    \\{
    \\    "rpc": "2.0",
    \\    "id": 1,
    \\    "result": {
    \\        "capabilities": {
    \\        },
    \\        "serverInfo": {
    \\            "name": "ghostty-lsp",
    \\            "version": "0.0.1"
    \\        }
    \\    }
    \\}
    ;
}
