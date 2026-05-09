# INTERCAL LSP server (educational stub)

A minimal JSON-RPC 2.0 over stdio Language Server Protocol implementation for INTERCAL, in zsh. Implements:

- `initialize` / `initialized`
- `textDocument/didOpen` / `didChange` / `didClose`
- `textDocument/publishDiagnostics` (driven by invoking `intercalc.sh`)
- `shutdown` / `exit`

## Usage

Configure your editor's LSP client to launch `src/lsp/intercal_lsp.sh` with stdio transport. Example for VS Code (`settings.json`):

    "intercal.lsp.serverPath": "/path/to/repo/src/lsp/intercal_lsp.sh"

Or for Neovim with nvim-lspconfig:

    require("lspconfig").configs.intercal = {
      default_config = {
        cmd = { "/path/to/repo/src/lsp/intercal_lsp.sh" },
        filetypes = { "intercal" },
        root_dir = function() return vim.fn.getcwd() end,
      },
    }

## Logging

Logs to `/tmp/intercal_lsp.log` (override with `INTERCAL_LSP_LOG`).

## Limitations

- No semantic tokens, hover, completion, go-to-definition, or rename.
- Diagnostics are line 0 character 0 (not span-precise).
- JSON parsing is regex-based; assumes well-formed client input.
- No incremental parsing.

A production LSP would add the missing methods, switch to a real JSON parser, and expose the parser's per-statement diagnostics with precise spans. See proposal #18 in `docs/improvement-proposals.md` for the full sketch.
