const std = @import("std");
const logging = @import("logging/log.zig");
const lsp_structs = @import("lsp/structs.zig");
const rpc = @import("lsp/rpc.zig");

pub fn main() !void {
    // setup
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    const allocator = gpa.allocator();
    defer {
        const c = gpa.deinit();
        switch (c) {
            // .ok => std.debug.print("deinit ok\n", .{}),
            .ok => {},
            .leak => std.debug.print("leaked\n", .{}),
        }
    }

    // Setup Logging
    // const logger = try logging.Logger.init( "/Users/robrossmiller/Projects/ghostty-lsp/log.txt", allocator,);
    // defer logger.deinit();
    // try stderr.writeAll("ghostty-lsp started\n");
    try stderr.writeAll("ghostty-lsp started\n");

    // write incomming messages to a file (delete-me after dev)
    // const messages_file = try std.fs.cwd().createFile( "/Users/robrossmiller/Projects/ghostty-lsp/messages.jsonc", .{ .read = true },);
    // defer messages_file.close();
    // try messages_file.writeAll("[");
    // defer { messages_file.writeAll("]") catch {}; }

    // Start reading messages
    while (true) {
        try stderr.writeAll("loop\n");

        // parse the message
        // base reader should return the method and contents separately
        // so contents slice can be reused
        try stderr.writeAll("parsing base message\n");
        const parsed = try rpc.BaseMessage.readMessage(allocator, stdin.reader());
        // const parsed = rpc.BaseMessage.readMessage(allocator, stdin.reader()) catch |err| {
        //     try stderr.writeAll("outter error reading contents\n");
        //     return err;
        // };
        defer parsed.deinit(); // this get's called on every loop
        try stderr.writeAll("base message parsed\n");

        const base_message = parsed.value;
        defer base_message.deinit(allocator);
        const log_msg = try std.fmt.allocPrint(allocator, "Message received: {s}", .{base_message.method});
        try stderr.writeAll(log_msg);

        // handle client messages and requests
        //TODO replace with enum
        //impl json parse
        //https://www.reddit.com/r/Zig/comments/1bignpf/json_serialization_and_taggeddiscrimated_unions/
        //https://zigbin.io/651078
        if (std.mem.eql(u8, base_message.method, "initialize")) {
            try stderr.writeAll("reading initialize\n");
            const init_reader = rpc.MessageReader(lsp_structs.RequestMessage(lsp_structs.InitializeParams));
            const init_parsed = try init_reader.readMessage(allocator, &base_message, null);
            defer init_parsed.deinit();
            const params = try std.json.stringifyAlloc(allocator, init_parsed.value.params, .{ .whitespace = .indent_2 });
            try stderr.writeAll(params);
            try stderr.writeAll("\n");
            try write_response(allocator, stdout.writer());
        } else if (std.mem.eql(u8, base_message.method, "initialized")) {
            //
        }
    }
}

fn write_response(allocator: std.mem.Allocator, stdout: std.fs.File.Writer) !void {
    const r = lsp_structs.newInitializeResponse();
    const msg = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n{s}", .{ r.len, r });
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}
