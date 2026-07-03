# Architecture lens — layout and separation of concerns

Detailed material for SKILL.md workflow step 3 (Architecture lens). Sources: `:h lua-guide`, `:h 'runtimepath'`, `:h initialization`, `:h lsp-config`.

## Officially documented directory layout

Neovim discovers config through `'runtimepath'`; these subdirectories have defined meanings (`:h 'runtimepath'`, `:h lua-guide`):

| Path                                          | Loaded                               | Purpose                                                                                                                                                                              |
| --------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `init.lua` (or `init.vim`, never both)        | at startup                           | Entry point. Keep it a thin loader (`require(...)` calls), not a monolith.                                                                                                           |
| `lua/**/*.lua`                                | on `require()`                       | Lua modules. Only reachable via `require`; nothing here loads automatically.                                                                                                         |
| `plugin/*.lua`                                | at startup, automatically            | Scripts that must run unconditionally. Runs _after_ `init.lua`.                                                                                                                      |
| `after/plugin/*.lua`                          | at startup, after all `plugin/` dirs | Overrides to plugin-set values. Rarely needed in a personal config — prefer plugin-manager hooks.                                                                                    |
| `ftplugin/<filetype>.lua`                     | when a buffer of that filetype opens | Filetype-local options/keymaps. Prefer this over `FileType` autocmds in central files.                                                                                               |
| `lsp/<name>.lua`                              | on `vim.lsp.enable('<name>')`        | Returns a table merged into `vim.lsp.config['<name>']` (`:h lsp-config`). `after/lsp/<name>.lua` also works and wins merge order over plugin-provided configs (e.g. nvim-lspconfig). |
| `colors/`, `queries/`, `snippets/`, `syntax/` | on demand                            | Colorschemes, treesitter query overrides, snippets, legacy syntax.                                                                                                                   |

Findings to raise:

- **Both `init.lua` and `init.vim` present** — Neovim refuses to load both (`:h config`). High.
- **Monolithic `init.lua`** — a 200+ line `init.lua` doing options, keymaps, autocmds, and plugin setup inline is a Low/advisory structure finding. `:h lua-guide-modules` documents `lua/` + `require()` as the sanctioned on-demand mechanism ("the Lua equivalent of Vimscript's autoload"); splitting is the documented tool, but no official doc mandates a split — keep it advisory.
- **`FileType` autocmd farms in a central file** where `ftplugin/<ft>.lua` is the documented mechanism. Low.
- **LSP server settings inlined in plugin specs or a monolithic `lsp.lua`** when the target is 0.11+ — the documented home is one file per server under `lsp/` (or `after/lsp/`), with shared defaults via `vim.lsp.config('*', ...)`. Medium if it duplicates what `lsp/` files already set; Low (advisory) when no `lsp/` files exist and nothing is duplicated.

## Separation-of-concerns heuristics

The official docs do not mandate module names; judge by responsibility, not by naming. A well-separated config typically isolates:

- **Options** (`vim.o`/`vim.opt`) — no keymaps, no autocmds mixed in.
- **Keymaps** — global maps only; buffer-local maps belong to `LspAttach`/`ftplugin`.
- **Autocmds** — each in a named `augroup` (see performance lens for `clear` semantics).
- **Plugin manager bootstrap + specs** — one spec file per plugin scales better than one giant table; either is acceptable, but mixed responsibility inside a spec (e.g. a colorscheme spec that also sets diagnostics globally) is a finding.
- **LSP** — server enablement/attach behavior separate from per-server settings (`lsp/` files).

Findings to raise:

- A module with two unrelated responsibilities (e.g. `options.lua` defining keymaps). Low.
- `require`-time side effects in shared utility modules (a `utils/` module that sets options when required). Medium — it makes load order load-bearing.
- Circular `require` between config modules. High — it errors at startup under `vim.loader` cache misses and is always a design smell.
- Plugin-spec files that reach into other specs' state instead of using the plugin manager's dependency/priority mechanism. Medium.

## What NOT to flag

- Flat `lua/plugins/*.lua` vs nested trees — both are fine; consistency within the config is what matters.
- Personal module naming (`config/`, `core/`, `user/` are all common); the lens judges responsibility boundaries, not names.
- Using a plugin manager at all (see `modern-patterns.md` for the `vim.pack` trade-off discussion).
