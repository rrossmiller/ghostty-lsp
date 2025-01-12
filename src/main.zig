const std = @import("std");
const rpc = @import("rpc/rpc.zig");
const lsp = @import("lsp/lsp.zig");
const lsp_structs = @import("lsp/structs.zig");
const State = @import("analysis/state.zig").State;

pub fn main() !void {
    // setup
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    // var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const c = gpa.deinit();
        switch (c) {
            // .ok => std.debug.print("deinit ok\n", .{}),
            .ok => {},
            .leak => std.debug.print("leaked\n", .{}),
        }
    }

    std.log.info("ghostty-lsp started", .{});

    var state = State.init(allocator);
    defer state.deinit();
    // var state = State{};
    // Start reading messages
    while (true) {
        // parse the message
        const parsed = try rpc.BaseMessage.readMessage(allocator, stdin.reader());
        defer parsed.deinit();
        const base_message = parsed.value;
        defer base_message.deinit(allocator);

        try handle_message(allocator, base_message, &state, stdout);
    }
}

fn handle_message(allocator: std.mem.Allocator, base_message: rpc.BaseMessage, state: *State, stdout: std.fs.File) !void {
    //TODO replace with enum?
    //impl json parse
    //https://www.reddit.com/r/Zig/comments/1bignpf/json_serialization_and_taggeddiscrimated_unions/
    //https://zigbin.io/651078

    // std.debug.print("\n\n\n", .{});
    // std.debug.print("{s}:\n{s}\n", .{ state.uri, state.text });
    // std.debug.print("\n\n\n", .{});
    switch (try lsp.MessageType.get(base_message.method)) {
        // Requests
        .Initialize => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.InitializeParams));
            defer parsed.deinit();
            std.log.info("Connected to: {s}", .{parsed.value.params.?.clientInfo.name});
            const init_res = lsp_structs.newInitializeResponse(parsed.value.id);
            try write_response(allocator, stdout.writer(), init_res);
        },
        // Notifications
        .DidOpen => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.DidOpenParams));
            defer parsed.deinit();
            // store the text in the state map
            const params = parsed.value.params.?;
            try state.open_document(params.textDocument.uri, params.textDocument.text);
        },
        .DidChange => {
            std.debug.print("did change\n", .{});
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.DidChangeParams));
            defer parsed.deinit();
            const params = parsed.value.params.?;
            for (params.contentChanges, 0..) |change, i| {
                std.debug.print("update{d} {s}: {d}\n", .{ i, params.textDocument.uri, change.text.len });
                try state.update_document(params.textDocument.uri, change.text);
            }
            std.debug.print("{s}\n", .{state.documents.get(params.textDocument.uri).?});
        },
        // .DidClose => {
        //     std.debug.print("did close\n", .{});
        // },
        // .DidSave => {
        //     std.debug.print("did save\n", .{});
        // },
        // .Shutdown => {
        //     std.log.info("\n***Thanks for playing***\n", .{});
        // },
        else => {
            std.log.info("Message Recieved: {s}", .{base_message.method});
        },
    }
}

fn write_response(allocator: std.mem.Allocator, stdout: std.fs.File.Writer, res: anytype) !void {
    const r = try std.json.stringifyAlloc(allocator, res, .{ .whitespace = .indent_2 });
    defer allocator.free(r);
    const msg = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n{s}", .{ r.len, r });
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}

test "test read base then init (test rollback)" {
    const allocator = std.testing.allocator;
    // make a file to be a standin for stdin
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();
    const f = try tmp_dir.dir.createFile("tmp.txt", .{ .read = true });
    defer f.close();
    const json =
        \\{"id":1,"params":{"workspaceFolders":null,"processId":12274,"clientInfo":{"name":"Neovim","version":"0.10.2"},"rootPath":null,"rootUri":null,"workDoneToken":"1","trace":"off","capabilities":{"workspace":{"configuration":true,"didChangeConfiguration":{"dynamicRegistration":false},"workspaceFolders":true,"applyEdit":true,"workspaceEdit":{"resourceOperations":["rename","create","delete"]},"didChangeWatchedFiles":{"relativePatternSupport":true,"dynamicRegistration":true},"semanticTokens":{"refreshSupport":true},"inlayHint":{"refreshSupport":true},"symbol":{"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"dynamicRegistration":false}},"window":{"workDoneProgress":true,"showMessage":{"messageActionItem":{"additionalPropertiesSupport":false}},"showDocument":{"support":true}},"textDocument":{"formatting":{"dynamicRegistration":true},"rangeFormatting":{"dynamicRegistration":true},"completion":{"completionItemKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]},"completionList":{"itemDefaults":["editRange","insertTextFormat","insertTextMode","data"]},"completionItem":{"documentationFormat":["markdown","plaintext"],"snippetSupport":false,"commitCharactersSupport":false,"preselectSupport":false,"deprecatedSupport":false},"dynamicRegistration":false,"contextSupport":false},"references":{"dynamicRegistration":false},"documentHighlight":{"dynamicRegistration":false},"documentSymbol":{"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"hierarchicalDocumentSymbolSupport":true,"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":true,"tagSupport":{"valueSet":[1,2]},"dataSupport":true},"inlayHint":{"resolveSupport":{"properties":["textEdits","tooltip","location","command"]},"dynamicRegistration":true},"callHierarchy":{"dynamicRegistration":false},"implementation":{"linkSupport":true},"typeDefinition":{"linkSupport":true},"semanticTokens":{"requests":{"full":{"delta":true},"range":false},"overlappingTokenSupport":true,"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"serverCancelSupport":false,"augmentsSyntaxTokens":true,"multilineTokenSupport":false,"dynamicRegistration":false,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"formats":["relative"]},"rename":{"prepareSupport":true,"dynamicRegistration":true},"synchronization":{"didSave":true,"dynamicRegistration":false,"willSaveWaitUntil":true,"willSave":true},"diagnostic":{"dynamicRegistration":false},"codeAction":{"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["","quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"resolveSupport":{"properties":["edit"]},"dynamicRegistration":true,"isPreferredSupport":true,"dataSupport":true},"hover":{"contentFormat":["markdown","plaintext"],"dynamicRegistration":true},"signatureHelp":{"signatureInformation":{"documentationFormat":["markdown","plaintext"],"parameterInformation":{"labelOffsetSupport":true},"activeParameterSupport":true},"dynamicRegistration":false},"definition":{"linkSupport":true,"dynamicRegistration":true},"declaration":{"linkSupport":true}},"general":{"positionEncodings":["utf-16"]}}},"jsonrpc":"2.0","method":"initialize"}
    ;
    const msg = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n{s}", .{ json.len, json });
    defer allocator.free(msg);
    try f.writeAll(msg);
    try f.seekTo(0);

    // read base
    const base_parsed = try rpc.BaseMessage.readMessage(allocator, f.reader());
    defer base_parsed.deinit();
    const base_message = base_parsed.value;
    defer base_message.deinit(allocator);
    try std.testing.expectEqualStrings("initialize", base_message.method);
    try std.testing.expectEqual(1, base_message.id);
    try std.testing.expect(base_message.contents.?.len > 0);
    try std.testing.expectEqualStrings(json, base_message.contents.?);

    // read init
    const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.InitializeParams);
    defer parsed.deinit();
    const message = parsed.value;
    try std.testing.expectEqualStrings("Neovim", message.clientInfo.name);
}
