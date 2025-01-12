build:
    @clear
    zig build
test:
    @clear
    zig test src/analysis/state.zig
    # zig test src/rpc/rpc.zig
    # zig test src/main.zig

