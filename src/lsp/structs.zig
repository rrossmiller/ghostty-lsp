pub fn RequestMessage(comptime T: type) type {
    return struct {
        jsonrpc: []const u8 = "2.0",
        id: ?u32 = null,
        method: []u8,

        // The method's params.
        params: ?T = null,
    };
}

pub fn ResponseMessage(comptime T: type) type {
    return struct {
        rpc: []const u8 = "2.0",
        id: ?u32 = 1,
        result: T,
    };
}
// COMMON
const TextDocumentIdentifier = struct {
    uri: []const u8,
};
const Position = struct {
    line: u32,
    character: u32,
};
//
// INITIALIZE >
pub const InitializeParams = struct {
    clientInfo: ClientInfo,
};
const ClientInfo = struct {
    name: []u8,
    version: []u8,
};

pub const InitializeResult = struct {
    capabilities: ServerCapabilities = .{},
    serverInfo: ServerInfo = .{},
};
pub const ServerCapabilities = struct {
    textDocumentSync: u16 = 1,
    hoverProvider: bool = true,
    // completionProvider: CompletionOptions = .{},
    // https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_completion
};
const CompletionOptions = struct {
    //
};
pub const ServerInfo = struct {
    name: []const u8 = "ghostty-lsp",
    version: []const u8 = "0.0.1",
};
pub fn newInitializeResponse(id: ?u32) ResponseMessage(InitializeResult) {
    const r = ResponseMessage(InitializeResult){
        .id = id,
        .result = .{},
    };
    return r;
}
// < INITIALIZE

//  TEXTDOCUMENT/HOVER >
pub const HoverParams = struct {
    textDocument: TextDocumentIdentifier,
    position: Position,
};
pub const TextDocumentPositionParams = struct {
    // The text document.
    textDocument: TextDocumentIdentifier,

    //  The position inside the text document.
    position: Position,
};

pub const HoverResult = struct {
    contents: []const u8,
};
pub fn newHoverResponse(id: ?u32, contents: []const u8) ResponseMessage(HoverResult) {
    return .{
        .id = id,
        .result = .{ .contents = contents },
    };
}

//< TEXTDOCUMENT/HOVER

// document/didOpen >
pub const DidOpenParams = struct {
    textDocument: TextDocumentItem,
};
const TextDocumentItem = struct {
    //  The text document's URI.
    uri: []const u8,

    // The text document's language identifier.
    languageId: []const u8,

    // The version number of this document (it will increase after each
    // change, including undo/redo).
    version: u8,

    // The content of the opened text document.
    text: []const u8,
};
// < document/didOpen
// document/didChange >
pub const DidChangeParams = struct {
    textDocument: VersionedTextDocumentIdentifier,
    contentChanges: []TextDocumentContentChangeEvent,
};
const VersionedTextDocumentIdentifier = struct {
    uri: []const u8,
    version: u8,
};
pub const TextDocumentContentChangeEvent = struct {
    text: []const u8,
};
// < document/didChange
// document/didClose >
pub const DidCloseParams = struct {
    textDocument: TextDocumentIdentifier,
};
// < document/didClose
