build:
    @clear
    zig build
test:
    @clear
    zig test src/rpc/rpc.zig
