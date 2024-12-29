const std = @import("std");
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
    // write logs to a file
    //TODO: make this a real log file
    const file = try std.fs.cwd().createFile(
        "/Users/robrossmiller/Projects/ghostty-lsp/logs.jsonc",
        .{ .read = true },
    );
    defer file.close();

    // Start reading messages
    while (true) {
        const message = try rpc.readMessage(allocator, stdin.reader(), file);
        try file.writeAll(message.value.method);
        try file.writeAll("\n//abc\n");
        try handle_message(allocator, stdout.writer());
        message.deinit();
    }
}

fn handle_message(allocator: std.mem.Allocator, stdout: std.fs.File.Writer) !void {
    const r = rpc_response.newInitializeResponse();
    const msg = try std.fmt.allocPrint(allocator, "Content-Length: {d}\r\n\r\n{s}", .{ r.len, r });
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}
