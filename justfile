build:
    @clear
    zig build
test:
    @clear
    zig test src/rpc/rpc.zig
    zig test src/main.zig

