build: parse-docs
    @clear
    zig build

build-nvim: build
    mkdir -p ~/.local/state/nvim/ghostty-lsp/
    rm ~/.local/state/nvim/ghostty-lsp/lsp
    cp zig-out/bin/ghostty-lsp ~/.local/state/nvim/ghostty-lsp/lsp

test:
    @clear
    zig test src/docs/docs.zig
    @#zig test src/lsp/lsp.zig
    @# zig test src/analysis/parser.zig
    @# zig test src/analysis/state.zig
    @# zig test src/rpc/rpc.zig
    @# zig test src/main.zig

parse-docs:
    @cd docs; python3 parse.py
