# Modern API lens — 0.12-recommended implementations

Detailed material for SKILL.md workflow step 3 (Modern API lens). Snapshot 2026-07, Nvim 0.12.3 stable. Sources: `:h lsp-config`, `:h vim.pack`, `:h lua-guide`, `news-0.11.txt`, `news-0.12.txt`.

## LSP: the 0.11+ native mechanism

The documented setup (`:h lsp-config`, `:h lsp-new-config`) is:

1. Per-server config as `lsp/<name>.lua` on the runtimepath returning a config table, or `vim.lsp.config('<name>', {...})`.
2. Shared defaults via `vim.lsp.config('*', {...})`.
3. Activation via `vim.lsp.enable('<name>')`. In 0.12, `enable()` also starts/stops clients at runtime, so toggling is safe.
4. Buffer-local behavior in an `LspAttach` autocmd with a named group (`:h lsp-attach`).

Merge order (`:h lsp-config-merge`, increasing priority): `'*'` config → `lsp/<name>.lua` files → `after/lsp/<name>.lua` files → `vim.lsp.config()` calls. The FAQ (`:h lsp-faq`) recommends `after/lsp/` for personal overrides so plugin-provided configs (nvim-lspconfig) do not win.

Findings to raise:

- `require('lspconfig').X.setup{}` on a 0.11+ target — deprecated by nvim-lspconfig itself; migrate to `vim.lsp.config`/`vim.lsp.enable` (nvim-lspconfig stays installed as the `lsp/` config data source). Medium.
- Manual reimplementation of 0.11/0.12 default keymaps: `grn` (rename), `grr` (references), `gri` (implementation), `gra` (code action), `gO` (document symbols), `K` (hover), `i_CTRL-S` (signature help); 0.12 adds `grt` (type definition) and `grx` (codelens run). Redefining one identically is Low noise; overriding with different behavior (e.g. a picker UI) is legitimate — do not flag.
- Manual completion wiring (omnifunc glue, custom autotrigger autocmds) where `vim.lsp.completion.enable(true, client_id, bufnr, {autotrigger=...})` (0.11) or the `'autocomplete'` option (0.12) is the built-in path. Only advisory when a completion plugin (blink.cmp, nvim-cmp) owns completion — plugins remain a valid choice. Low.
- `vim.lsp.with()` or global `vim.lsp.handlers` overrides for hover/signature float config — 0.11 stopped routing `vim.lsp.buf.*` through global handlers; pass config to the call site or use `vim.diagnostic.config()`. Medium.
- Diagnostics assumptions: since 0.11 `virtual_text` is **off by default** — a config relying on old defaults silently lost virtual text; configure explicitly via `vim.diagnostic.config()`. Low unless the config visibly expects it.

## Plugin management: vim.pack vs third-party managers

`vim.pack` (0.12, `:h vim.pack`) is official but documented as "experimental, yet should be stable enough for daily use". API: `vim.pack.add({specs}, {opts})`, `vim.pack.update()`, `vim.pack.del()`, `vim.pack.get()`; lockfile `nvim-pack-lock.json` (docs recommend version-controlling it); build hooks via `PackChanged` autocmd events.

Official docs make **no recommendation** between vim.pack and lazy.nvim and do not discourage third-party managers. Therefore:

- Using lazy.nvim (or another maintained manager) on 0.12 is **not a finding**.
- Using an unmaintained manager (packer.nvim, vim-plug in a Lua config) is a finding (see deprecated-apis.md).
- If the user asks about migrating, present the factual deltas: vim.pack has no dependency resolution and no declarative lazy-loading framework (`load=false` + manual `:packadd` or a custom `load` function only), but removes a bootstrap dependency and gains 0.12's in-place Lua path-cache update on `:packadd`.

## Core Lua idioms (`:h lua-guide`)

| Concern  | Recommended                                                                                                                                                                                                    | Flag instead                                                                                                                                     |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Keymaps  | `vim.keymap.set()` with `desc`; buffer-local via `buf` (0.12 renamed from `buffer`); `remap` not `noremap`                                                                                                     | Raw `nvim_set_keymap()` / `vim.api.nvim_buf_set_keymap()` in config code (Low); `noremap` key in opts (it is ignored — Medium, silent misconfig) |
| Options  | `vim.o` for scalar access; `vim.opt` for list/map options and `:append()`/`:remove()`; note `vim.o` also accepts Lua tables for list options now. No official perf difference is documented — do not claim one | `vim.cmd('set ...')` string soup for options that have a Lua path (Low, consistency)                                                             |
| Autocmds | `nvim_create_autocmd` with a Lua `callback`, `desc`, and a named `augroup` (`clear = true` where re-sourcing matters)                                                                                          | Groupless autocmds in re-sourceable files (duplicate on re-source — Medium); `vim.cmd('autocmd ...')` (Low)                                      |

"Re-sourceable" means the code can execute more than once per session without a cache in between: `init.lua`, `plugin/`, `after/plugin/`, and `ftplugin/` files (`:so %`, re-editing config). Modules loaded via `require()` are cached, and plugin-manager `config` callbacks re-run only on explicit manager reload — groupless autocmds there are Low, not Medium.
| Vimscript calls | `vim.cmd.colorscheme('x')` programmatic form; `vim.fn` for functions | — |
| Ex-command scripting | `vim.api` / `vim.o` where an API exists | — |

## 0.12 behavior changes a config should account for

- `'exrc'` now searches **parent directories** and its trust flow changed (use `:trust`) — a config enabling `exrc` should be aware. Low/informational.
- Default `'statusline'` now shows diagnostics counts and LSP progress — a statusline plugin duplicating only that is advisory-redundant (do not flag plugins that do more, e.g. lualine).
- `'shelltemp'` default flipped to false; `:TOhtml` now needs `:packadd nvim.tohtml`; `'spellfile'` default location moved; treesitter highlighting is on by default for markdown.
- ui2 (`vim._core.ui2`) is experimental — a config force-enabling it deserves an informational note, not a violation.

## What NOT to flag

- Anything whose replacement postdates the target version.
- Community idioms with no official ruling (plugin spec shapes, module naming, lazy-loading strategies) — those belong to the architecture lens only when responsibilities are mixed.
- Performance claims that official docs do not make (see performance.md for what is actually documented).
