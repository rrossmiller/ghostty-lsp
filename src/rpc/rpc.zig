const std = @import("std");
const RequestMessage = @import("structs.zig").RequestMessage;

pub fn readMessage(allocator: std.mem.Allocator, stdin: std.fs.File.Reader, messages_file: std.fs.File) !std.json.Parsed(RequestMessage) {
    try stdin.skipBytes(16, .{}); // skip "Content-Length: "
    // get the length of the message in the header
    const buf = try stdin.readUntilDelimiterAlloc(allocator, '\r', 10);
    defer allocator.free(buf);
    const msg_size = try std.fmt.parseInt(u32, buf, 10);
    try messages_file.writeAll("//");
    try messages_file.writeAll(buf);
    try messages_file.writeAll("\n");

    // skip newlines "\r\n\r\n"
    try stdin.skipBytes(3, .{});
    const contents = try allocator.alloc(u8, msg_size);
    defer allocator.free(contents);
    _ = try stdin.readAll(contents);

    try messages_file.writeAll(contents);
    try messages_file.writeAll("\n\n");

    const parsed = try std.json.parseFromSlice(RequestMessage, allocator, contents, .{ .ignore_unknown_fields = true });
    return parsed;
}

test "test readMessage" {
    const alloc = std.testing.allocator;
    // make a file to be a standin for stdin
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();
    const f = try tmp_dir.dir.createFile("tmp.txt", .{ .read = true });
    defer f.close();
    const x = try tmp_dir.dir.createFile("asdf.txt", .{ .read = true });
    defer x.close();
    const json =
        \\{"id":1,"params":{"workspaceFolders":null,"processId":12274,"clientInfo":{"name":"Neovim","version":"0.10.2"},"rootPath":null,"rootUri":null,"workDoneToken":"1","trace":"off","capabilities":{"workspace":{"configuration":true,"didChangeConfiguration":{"dynamicRegistration":false},"workspaceFolders":true,"applyEdit":true,"workspaceEdit":{"resourceOperations":["rename","create","delete"]},"didChangeWatchedFiles":{"relativePatternSupport":true,"dynamicRegistration":true},"semanticTokens":{"refreshSupport":true},"inlayHint":{"refreshSupport":true},"symbol":{"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"dynamicRegistration":false}},"window":{"workDoneProgress":true,"showMessage":{"messageActionItem":{"additionalPropertiesSupport":false}},"showDocument":{"support":true}},"textDocument":{"formatting":{"dynamicRegistration":true},"rangeFormatting":{"dynamicRegistration":true},"completion":{"completionItemKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]},"completionList":{"itemDefaults":["editRange","insertTextFormat","insertTextMode","data"]},"completionItem":{"documentationFormat":["markdown","plaintext"],"snippetSupport":false,"commitCharactersSupport":false,"preselectSupport":false,"deprecatedSupport":false},"dynamicRegistration":false,"contextSupport":false},"references":{"dynamicRegistration":false},"documentHighlight":{"dynamicRegistration":false},"documentSymbol":{"symbolKind":{"valueSet":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26]},"hierarchicalDocumentSymbolSupport":true,"dynamicRegistration":false},"publishDiagnostics":{"relatedInformation":true,"tagSupport":{"valueSet":[1,2]},"dataSupport":true},"inlayHint":{"resolveSupport":{"properties":["textEdits","tooltip","location","command"]},"dynamicRegistration":true},"callHierarchy":{"dynamicRegistration":false},"implementation":{"linkSupport":true},"typeDefinition":{"linkSupport":true},"semanticTokens":{"requests":{"full":{"delta":true},"range":false},"overlappingTokenSupport":true,"tokenModifiers":["declaration","definition","readonly","static","deprecated","abstract","async","modification","documentation","defaultLibrary"],"serverCancelSupport":false,"augmentsSyntaxTokens":true,"multilineTokenSupport":false,"dynamicRegistration":false,"tokenTypes":["namespace","type","class","enum","interface","struct","typeParameter","parameter","variable","property","enumMember","event","function","method","macro","keyword","modifier","comment","string","number","regexp","operator","decorator"],"formats":["relative"]},"rename":{"prepareSupport":true,"dynamicRegistration":true},"synchronization":{"didSave":true,"dynamicRegistration":false,"willSaveWaitUntil":true,"willSave":true},"diagnostic":{"dynamicRegistration":false},"codeAction":{"codeActionLiteralSupport":{"codeActionKind":{"valueSet":["","quickfix","refactor","refactor.extract","refactor.inline","refactor.rewrite","source","source.organizeImports"]}},"resolveSupport":{"properties":["edit"]},"dynamicRegistration":true,"isPreferredSupport":true,"dataSupport":true},"hover":{"contentFormat":["markdown","plaintext"],"dynamicRegistration":true},"signatureHelp":{"signatureInformation":{"documentationFormat":["markdown","plaintext"],"parameterInformation":{"labelOffsetSupport":true},"activeParameterSupport":true},"dynamicRegistration":false},"definition":{"linkSupport":true,"dynamicRegistration":true},"declaration":{"linkSupport":true}},"general":{"positionEncodings":["utf-16"]}}},"jsonrpc":"2.0","method":"initialize"}
    ;
    const msg = try std.fmt.allocPrint(alloc, "Content-Length: {d}\r\n\r\n{s}", .{ json.len, json });
    defer alloc.free(msg);
    try f.writeAll(msg);
    try f.seekTo(0);

    const stat = try f.stat();
    const b = try f.reader().readAllAlloc(alloc, stat.size);
    defer alloc.free(b);
    try f.seekTo(0);

    const parsed = try readMessage(alloc, f.reader(), x);
    defer parsed.deinit();
    const message = parsed.value;
    try std.testing.expectEqualStrings("initialize", message.method);
    try std.testing.expectEqual(1, message.id);
}
