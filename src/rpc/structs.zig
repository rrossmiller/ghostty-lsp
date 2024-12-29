pub const RequestMessage = struct {
    //  The request id.
    id: ?u32 = null,
    // The method to be invoked.
    method: []u8,

    //https://ziglang.org/documentation/master/#struct
    // make it generic
    // The method's params.
    // params?: array | object;

};

pub const ResponseMessage = struct {
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
