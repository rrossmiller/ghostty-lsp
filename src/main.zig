const std = @import("std");
const rpc = @import("rpc/rpc.zig");
const docs = @import("docs/docs.zig");
const lsp = @import("lsp/lsp.zig");
const lsp_structs = @import("lsp/structs.zig");
const State = @import("analysis/state.zig").State;

const version = "0.0.1";
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
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const aren_allocator = arena.allocator();

    // check if the --version command was called
    var args = std.process.args();
    _ = args.skip(); // skip name
    if (args.next()) |cmd| {
        if (std.mem.eql(u8, cmd, "--version") or
            std.mem.eql(u8, cmd, "-v"))
        {
            try stdout.writeAll(version);
            return;
        }
    }

    const p_docs = try docs.read_docs(allocator);
    defer p_docs.deinit();
    const docs_map = p_docs.value;
    std.log.info("ghostty-lsp started", .{});

    var state = State.init(allocator);
    defer state.deinit();
    // Start reading messages
    var run = true;
    while (run) {
        // parse the message
        const parsed = try rpc.BaseMessage.readMessage(aren_allocator, stdin.reader());
        defer parsed.deinit();
        const base_message = parsed.value;
        defer base_message.deinit(aren_allocator);

        run = try handle_message(aren_allocator, base_message, &state, stdout, &docs_map);
    }
}

fn handle_message(allocator: std.mem.Allocator, base_message: rpc.BaseMessage, state: *State, stdout: std.fs.File, docs_map: *const std.json.ArrayHashMap([]const u8)) !bool {
    //TODO
    //impl json parse
    //https://www.reddit.com/r/Zig/comments/1bignpf/json_serialization_and_taggeddiscrimated_unions/
    //https://zigbin.io/651078

    //TODO replace alloc with arena alloc and deinit on rtn?

    switch (try lsp.MessageType.get(base_message.method)) {
        // Requests
        .Initialize => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.InitializeParams));
            defer parsed.deinit();
            std.log.info("Connected to: {s}", .{parsed.value.params.?.clientInfo.name});
            const res = lsp_structs.newInitializeResponse(parsed.value.id);
            try write_response(allocator, stdout.writer(), res);
        },
        .Hover => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.HoverParams));
            defer parsed.deinit();

            const params = parsed.value.params.?;
            // const len = try std.fmt.allocPrint(allocator, "{d}", .{state.documents.get(params.textDocument.uri).?.len});
            if (state.documents.get(params.textDocument.uri)) |contents| {
                if (lsp.hover(&params, contents, docs_map)) |doc| {
                    // TODO do something interesting with hover
                    // const msg = try std.fmt.allocPrint(allocator, "Hovered word: {s}", .{word});
                    // defer allocator.free(msg);
                    const res = lsp_structs.newHoverResponse(parsed.value.id, doc);
                    try write_response(allocator, stdout.writer(), res);
                }
            }
        },
        .Completion => {
            std.debug.print("completion\n", .{});
        },
        // Notifications
        .DidOpen => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.DidOpenParams));
            defer parsed.deinit();
            // store the text in the state map
            const params = parsed.value.params.?;
            try state.open_document(params.textDocument.uri, params.textDocument.text);
            std.log.info("Opened: {s}", .{params.textDocument.uri});
        },
        .DidChange => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.DidChangeParams));
            defer parsed.deinit();
            const params = parsed.value.params.?;
            for (params.contentChanges) |change| {
                try state.update_document(params.textDocument.uri, change.text);
            }
        },
        .DidClose => {
            const parsed = try rpc.readMessage(allocator, &base_message, lsp_structs.RequestMessage(lsp_structs.DidCloseParams));
            defer parsed.deinit();
            const params = parsed.value.params.?;

            state.remove_doc(params.textDocument.uri);
            std.log.info("Close: {s}", .{params.textDocument.uri});
        },
        // .DidSave => {
        //     std.debug.print("did save\n", .{});
        // },
        .Shutdown => {
            std.log.info("Shutting down Ghostty LSP\n", .{});
            return false;
        },
        else => {
            std.log.info("Message Recieved: {s}", .{base_message.method});
        },
    }
    return true;
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
