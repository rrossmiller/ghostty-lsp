build:
    @clear
    zig build
    cp zig-out/bin/ghostty-lsp ~/.local/state/nvim/ghostty-lsp/lsp
test:
    @clear
    zig test src/parser/parser.zig
    # zig test src/analysis/state.zig
    # zig test src/rpc/rpc.zig
    # zig test src/main.zig
