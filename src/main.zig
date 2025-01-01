const std = @import("std");
const lsp_structs = @import("lsp/structs.zig");
const rpc = @import("lsp/rpc.zig");

pub fn main() !void {
    // setup
    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr().writer();
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

    try stderr.writeAll("ghostty-lsp started\n");

    // Start reading messages
    while (true) {
        // parse the message
        // base reader should return the method and contents separately
        // so contents slice can be reused
        const parsed = try rpc.BaseMessage.readMessage(allocator, stdin.reader());
        defer parsed.deinit(); // this get's called on every loop
        try stderr.writeAll("base message parsed\n");

        const base_message = parsed.value;
        defer base_message.deinit(allocator);
        const log_msg = try std.fmt.allocPrint(allocator, "Message received: {s}\n", .{base_message.method});
        defer allocator.free(log_msg);
        try stderr.writeAll(log_msg);

        // handle client messages and requests
        //TODO replace with enum
        //impl json parse
        //https://www.reddit.com/r/Zig/comments/1bignpf/json_serialization_and_taggeddiscrimated_unions/
        //https://zigbin.io/651078
        if (std.mem.eql(u8, base_message.method, "initialize")) {
            try stderr.writeAll("reading initialize\n");
            const init_reader = rpc.MessageReader(lsp_structs.RequestMessage(lsp_structs.InitializeParams));
            const init_parsed = try init_reader.readMessage(allocator, &base_message);
            defer init_parsed.deinit();
            const params = try std.json.stringifyAlloc(allocator, init_parsed.value.params, .{ .whitespace = .indent_2 });
            defer allocator.free(params);
            try stderr.writeAll("Params:\n");
            try stderr.writeAll(params);
            try stderr.writeAll("\n");
            try write_response(allocator, stdout.writer());
            // } else if (std.mem.eql(u8, base_message.method, "initialized")) {
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
