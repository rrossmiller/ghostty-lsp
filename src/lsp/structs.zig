pub fn RequestMessage(comptime T: type) type {
    return struct {
        jsonrpc: []const u8 = "2.0",
        //  The request id.
        id: ?u32 = null,
        // The method to be invoked.
        method: []u8,

        // The method's params.
        params: ?T = null,
    };
}
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

// INITIALIZE
pub const InitializeParams = struct {
    clientInfo: ClientInfo,
};
const ClientInfo = struct {
    name: []u8,
    version: []u8,
};
pub fn newInitializeResponse() []const u8 {
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
