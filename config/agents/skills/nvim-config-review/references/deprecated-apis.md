# Deprecations lens — deprecated/removed APIs and superseded plugins

Detailed material for SKILL.md workflow step 3 (Deprecations lens). Snapshot taken 2026-07 against Nvim 0.12.3 (stable; 0.12.0 released 2026-03-29). Sources: `runtime/doc/deprecated.txt`, `news-0.10/0.11/0.12.txt`, source greps of `runtime/lua` per release branch, GitHub repo status via API.

**Severity mapping** (deprecation ≠ removal — check the target version first):

- **High** — removed in the target version (errors), or present in target but already deleted on master ("0.13-dev" below: breaks on the next release). Actual deletion on master is the bar — a removal _schedule_ alone (e.g. `vim.deprecate(..., '0.13')` in the source) does not promote a Medium to High.
- **Medium** — deprecated in or before the target version; warns but works.
- Do not flag APIs whose deprecation postdates the target version.
- These tiers do not map 1:1 to the section headers of `runtime/doc/deprecated.txt` (an API listed under "DEPRECATED IN 0.8" may or may not be removed yet). When the tier is in doubt, check whether the symbol still exists in the target runtime's Lua source.
- A config key that merely _names_ a deprecated function (e.g. a plugin override table like `["vim.lsp.util.stylize_markdown"] = true`) is not a call. Report it as Low/informational when the deprecation makes the option inert on the target version; otherwise a note at most — never Medium/High on the name reference alone.

## Removed (error on 0.11/0.12 targets)

| Gone                                                                              | Replacement                                               | Removed in |
| --------------------------------------------------------------------------------- | --------------------------------------------------------- | ---------- |
| `vim.lsp.buf.formatting()` / `formatting_sync()` / `range_formatting()`           | `vim.lsp.buf.format({async=...})` / `format({range=...})` | 0.10       |
| `vim.lsp.util.get_progress_messages()`                                            | `vim.lsp.status()`                                        | 0.11       |
| `severity_limit` option (LSP diagnostic)                                          | `{severity = {min = ...}}`                                | 0.11       |
| `vim.diagnostic.disable()` / `is_disabled()` / legacy `enable(buf, ns)` signature | `vim.diagnostic.enable(enable, filter)` / `is_enabled()`  | 0.12       |
| Diagnostic signs via `sign_define()` / `:sign-define`                             | `signs` key of `vim.diagnostic.config()`                  | 0.12       |
| `Query:iter_matches()` `all` option                                               | —                                                         | 0.12       |
| `vim.diff()`                                                                      | `vim.text.diff()` (rename; old name deprecated)           | 0.12       |

## Deprecated, deleted on master — breaks on 0.13 (High on a 0.12 target)

| Deprecated                         | Replacement                                              | Since |
| ---------------------------------- | -------------------------------------------------------- | ----- |
| `vim.tbl_islist()`                 | `vim.islist()` (strict; gap-tolerant is `vim.isarray()`) | 0.10  |
| `vim.tbl_add_reverse_lookup()`     | none                                                     | 0.10  |
| `vim.lsp.get_active_clients()`     | `vim.lsp.get_clients()`                                  | 0.10  |
| `vim.lsp.buf_get_clients()`        | `vim.lsp.get_clients({bufnr=...})`                       | ≤0.8  |
| `vim.lsp.for_each_buffer_client()` | `vim.lsp.get_clients()` + loop                           | 0.10  |
| `vim.lsp.util.jump_to_location()`  | `vim.lsp.util.show_document(..., {focus=true})`          | 0.11  |
| `vim.lsp.util.trim_empty_lines()`  | `vim.split(s, ..., {trimempty=true})`                    | 0.10  |

## Deprecated, still present on master (Medium; warns)

| Deprecated                                                                                                                             | Replacement                                                                                                                     | Since |
| -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `vim.loop`                                                                                                                             | `vim.uv`                                                                                                                        | 0.10  |
| `vim.highlight`                                                                                                                        | `vim.hl`                                                                                                                        | 0.11  |
| `vim.tbl_flatten()`                                                                                                                    | `vim.iter(...):flatten():totable()`                                                                                             | 0.10  |
| `vim.validate(opts: table)` table form                                                                                                 | `vim.validate(name, value, validator, ...)`                                                                                     | 0.11  |
| `vim.diagnostic.goto_next()` / `goto_prev()`                                                                                           | `vim.diagnostic.jump({count=±1, float=true})`                                                                                   | 0.11  |
| `client.supports_method(...)` and all dot-calls on a client (`request`, `notify`, `stop`, `is_stopped`, `cancel_request`, `on_attach`) | method call: `client:supports_method(...)`                                                                                      | 0.11  |
| `vim.region()`                                                                                                                         | `vim.fn.getregionpos()`                                                                                                         | 0.11  |
| `vim.lsp.with()`                                                                                                                       | pass config to the `vim.lsp.buf.*` call; diagnostics: `vim.diagnostic.config(cfg, vim.lsp.diagnostic.get_namespace(client_id))` | 0.11  |
| `vim.lsp.start_client()`                                                                                                               | `vim.lsp.start()`                                                                                                               | 0.11  |
| `vim.lsp.buf.execute_command()`                                                                                                        | `Client:exec_cmd()`                                                                                                             | 0.11  |
| `vim.lsp.buf.completion`                                                                                                               | `vim.lsp.completion.get()` / `trigger()`                                                                                        | 0.11  |
| `vim.lsp.diagnostic.get_line_diagnostics()`                                                                                            | `vim.diagnostic.get()`                                                                                                          | old   |
| `termopen()`                                                                                                                           | `jobstart(..., {term=true})`                                                                                                    | 0.11  |
| `vim.loader.disable()`                                                                                                                 | `vim.loader.enable(false)`                                                                                                      | 0.11  |
| `nvim_buf_add_highlight()`                                                                                                             | `vim.hl.range()` or `nvim_buf_set_extmark()`                                                                                    | 0.11  |
| `nvim_out_write()` / `nvim_err_write()` / `nvim_err_writeln()`                                                                         | `nvim_echo()` (`{err=true}`)                                                                                                    | 0.11  |
| `nvim_notify()`                                                                                                                        | `nvim_echo()` / `vim.notify()`                                                                                                  | 0.11  |
| `nvim_buf_get_option()` etc. (all `nvim_{buf,win,}_{get,set}_option`)                                                                  | `nvim_get_option_value()` / `nvim_set_option_value()`                                                                           | 0.10  |
| `vim.health.report_*()`                                                                                                                | `vim.health.error/info/ok/start/warn()`                                                                                         | 0.10  |

## Deprecated in 0.12 (Medium on a 0.12 target)

| Deprecated                                          | Replacement                                      |
| --------------------------------------------------- | ------------------------------------------------ |
| `"buffer"` key in `vim.keymap.set()` / `del()` opts | `"buf"`                                          |
| `vim.lsp.set_log_level()` / `get_log_path()`        | `vim.lsp.log.set_level()` / `log.get_filename()` |
| `vim.lsp.semantic_tokens.start()` / `stop()`        | `vim.lsp.semantic_tokens.enable(true/false)`     |
| `vim.lsp.codelens.refresh()` / `clear()`            | `vim.lsp.codelens.enable(true/false)`            |
| `vim.lsp.stop_client()`                             | `Client:stop()`                                  |
| `vim.lsp.client_is_stopped()`                       | `vim.lsp.get_client_by_id()`                     |
| `vim.lsp.util.stylize_markdown()`                   | `vim.treesitter.start()` + `conceallevel=2`      |
| `nvim_set_decoration_provider` `on_line`            | `on_range`                                       |
| `"float"` in `vim.diagnostic.JumpOpts`              | `on_jump`                                        |
| `:ownsyntax` / `w:current_syntax`                   | `'winhighlight'`                                 |

## Grep patterns

Run these over the scope before reading files; confirm each hit in context (comments and version-guarded code are not findings).

```
grep -rn -E "vim\.loop\b|vim\.highlight\.|vim\.tbl_(islist|flatten|add_reverse_lookup)|vim\.region\(" <scope>
grep -rn -E "get_active_clients|buf_get_clients|for_each_buffer_client|start_client\(|jump_to_location|lsp\.with\(|stop_client\(|execute_command" <scope>
grep -rn -E "diagnostic\.(goto_next|goto_prev|disable|is_disabled)|sign_define" <scope>
grep -rn -E "client\.(supports_method|request|request_sync|notify|cancel_request|stop|is_stopped)\(" <scope>
grep -rn -E "lsp\.buf\.formatting|nvim_buf_(get|set)_option|nvim_win_(get|set)_option|nvim_(get|set)_option\(|nvim_buf_add_highlight|nvim_(out|err)_write|termopen\(" <scope>
grep -rn -E "vim\.diff\(|get_progress_messages|trim_empty_lines|vim\.health\.report_" <scope>
grep -rn -E "semantic_tokens\.(start|stop)\(|codelens\.(refresh|clear)\(|lsp\.(set_log_level|get_log_path)|client_is_stopped|stylize_markdown|get_buffers_by_client_id" <scope>
grep -rn -E "buffer\s*=\s*(true|bufnr|args\.buf|0)" <scope>   # keymap opts "buffer"→"buf" (0.12); check it is a vim.keymap.set opts table
grep -rn -E "require\(.(lspconfig|nvim-treesitter\.configs)" <scope>
```

## Plugins archived or superseded by built-ins (verified 2026-07)

| Plugin                                          | Status                                                                                                                     | Built-in / successor                                                                                      | Severity                                                                                                                                       |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| nvim-treesitter                                 | **Archived 2026-04-03**; `master` branch frozen (0.11-compat), `main` was the 0.12-only rewrite; no official successor yet | 0.12 core treesitter (`vim.treesitter.start()`, default markdown highlighting) + manual parser management | High if on `master` branch with a 0.12 target; Low (advisory) if on the `main` rewrite with current APIs; report the archive status either way |
| packer.nvim                                     | README declares it unmaintained; no commits since 2024-03                                                                  | lazy.nvim (community) or `vim.pack` (0.12 built-in)                                                       | High                                                                                                                                           |
| null-ls.nvim                                    | Repo deleted (404)                                                                                                         | nvimtools/none-ls.nvim, or real LSP servers                                                               | High                                                                                                                                           |
| neodev.nvim                                     | Archived 2024-07                                                                                                           | folke/lazydev.nvim                                                                                        | High                                                                                                                                           |
| `require('lspconfig').X.setup{}` framework      | Deprecated by nvim-lspconfig itself (warns, will error)                                                                    | `vim.lsp.config()` / `vim.lsp.enable()`; nvim-lspconfig still fine as a _data_ source of `lsp/` configs   | Medium                                                                                                                                         |
| Comment.nvim / vim-commentary                   | Dormant; not archived                                                                                                      | Built-in `gc`/`gcc` (0.10)                                                                                | Low (advisory)                                                                                                                                 |
| vim-vsnip / UltiSnips for LSP snippet expansion | —                                                                                                                          | `vim.snippet` (0.10) + default `<Tab>` jumping (0.11)                                                     | Low                                                                                                                                            |
| lsp_signature.nvim                              | —                                                                                                                          | Built-in `vim.lsp.buf.signature_help()` + `i_CTRL-S` (0.11)                                               | Low                                                                                                                                            |
| fidget.nvim (progress only)                     | Active                                                                                                                     | `vim.lsp.status()`; 0.12 default 'statusline' shows progress                                              | Low                                                                                                                                            |
| nvim-osc52 / vim-oscyank                        | —                                                                                                                          | Built-in OSC 52 clipboard (0.10/0.11)                                                                     | Low                                                                                                                                            |
| editorconfig-vim                                | —                                                                                                                          | Built-in editorconfig (0.9+)                                                                              | Low                                                                                                                                            |
| lsp-inlayhints.nvim                             | —                                                                                                                          | `vim.lsp.inlay_hint` (0.10)                                                                               | Low                                                                                                                                            |
| vim-unimpaired (bracket maps)                   | —                                                                                                                          | Default `[q ]q [b ]b` etc. (0.11)                                                                         | Low                                                                                                                                            |
| nvim-cmp                                        | Active — **not** deprecated                                                                                                | `vim.lsp.completion.enable()` (0.11) + `'autocomplete'` (0.12) cover LSP-only setups                      | Do not flag; note the built-in option only if the user asks                                                                                    |

For any plugin not in this table, check its repo directly (`archived` flag, README notice) before flagging. A repo that has _moved_ (README relocation notice; the tracked repo is a mirror of a canonical home elsewhere) is Medium when the config tracks the mirror — recommend pointing the spec at the canonical URL; note if mirror-tracking is a stated, deliberate choice. Popularity or "the community moved on" is never grounds for a finding.
