pub const RequestMessage = struct {
    //  The request id.
    id: u32,
    // The method to be invoked.
    method: []u8,

    // The method's params.
    // params?: array | object;

    //https://ziglang.org/documentation/master/#struct
    // make it generic
};

pub const ResponseMessage = struct {
    //
};

pub fn newInitializeResponse() *const [378:0]u8 {
    return 
    \\{
    \\    "response": {
    \\        "rpc": "2.0",
    \\        "id": 1
    \\    },
    \\    "result": {
    \\        "capabilities": {
    \\            "textDocumentSync": 1,
    \\            "hoverProvider": false,
    \\            "definitionProvider": false,
    \\            "codeActionProvider": false 
    \\        },
    \\        "serverInfo": {
    \\            "name": "ghostty-lsp",
    \\            "version": "0.0.1"
    \\        }
    \\    }
    \\}
    ;
}
