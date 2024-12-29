const std = @import("std");
const logging = @import("logging/log.zig");
const rpc_response = @import("rpc/structs.zig");
const RequestMessage = rpc_response.RequestMessage;
const rpc = @import("rpc/rpc.zig");

pub fn main() !void {
    // setup
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
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
    // Setup Logging
    const logger = try logging.Logger.init(
        "/Users/robrossmiller/Projects/ghostty-lsp/log.txt",
        allocator,
    );
    defer logger.deinit();
    try logger.log("ghostty-lsp started\n");

    // write incomming messages to a file
    const messages_file = try std.fs.cwd().createFile(
        "/Users/robrossmiller/Projects/ghostty-lsp/messages.jsonc",
        .{ .read = true },
    );
    defer messages_file.close();
    try messages_file.writeAll("[");
    defer {
        messages_file.writeAll("]") catch {};
    }

    // Start reading messages
    var parsed: std.json.Parsed(RequestMessage) = undefined;
    defer parsed.deinit();
    var first = true;
    while (true) {
        if (!first) {
            try messages_file.writeAll(",\n");
        } else {
            first = false;
        }
        parsed = try rpc.readMessage(allocator, stdin.reader(), messages_file);
        const message = parsed.value;
        const log_msg = try std.fmt.allocPrint(allocator, "Message received: {s}\n", .{message.method});
        try logger.log(log_msg);

        //TODO replace with enum
        //impl json parse
        //https://www.reddit.com/r/Zig/comments/1bignpf/json_serialization_and_taggeddiscrimated_unions/
        //https://zigbin.io/651078
        if (std.mem.eql(u8, message.method, "initialize")) {
            try write_response(allocator, stdout.writer());
        } else if (std.mem.eql(u8, message.method, "initialized")) {
            //
        }
    }
}

fn write_response(allocator: std.mem.Allocator, stdout: std.fs.File.Writer) !void {
    const r = rpc_response.newInitializeResponse();
    const msg = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n{s}", .{ r.len, r });
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}
