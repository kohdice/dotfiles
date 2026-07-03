# Performance lens — startup and runtime cost

Detailed material for SKILL.md workflow step 3 (Performance lens). Snapshot 2026-07, Nvim 0.12.3. Sources: `:h --startuptime`, `:h slow-start`, `:h 'runtimepath'`, `:h lua-guide`, `:h vim.loader`, `news-0.12.txt`.

**Honesty rule for this lens**: much community "perf lore" has no official backing. Report a claim as _documented_ only when a `:h` tag says so; otherwise label it _reasoned_ (explain the mechanism: work done at startup vs deferred, per-event vs one-shot) and keep severity Low. Never invent benchmark numbers.

## Documented by official help

| Check                                                                              | Documented basis                                                                                                                                 | Finding severity                                                                              |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| Wildcards or long lists in `'runtimepath'`                                         | `:h 'runtimepath'`: "For speed, use as few items as possible and avoid wildcards"                                                                | Medium                                                                                        |
| Interleaving `:packadd`/`vim.pack.add()` with other init code on <0.12 assumptions | news-0.12 PERFORMANCE: 0.12 updates the Lua path cache in place; on 0.11 each `:packadd` invalidated it                                          | Low (informational on 0.12)                                                                   |
| Mapping rhs `require('plugin').fn` outside a closure                               | `:h lua-guide-mappings-set`: loads the plugin when the mapping is _defined_; wrap in `function() ... end` to defer                               | Medium when the module is heavy and the map is defined at startup                             |
| Huge shada slowing startup                                                         | `:h slow-start`: test with `-i NONE`, tune `'shada'`                                                                                             | Only when evidence exists (user complaint, giant shada)                                       |
| Slow Lua loops without interrupt points                                            | `:h lua-guide-interrupt`: call `vim.wait(0, nil, 0)` periodically                                                                                | Low                                                                                           |
| `vim.loader.enable()`                                                              | `:h vim.loader.enable()` — byte-compilation cache, but explicitly "experimental/unstable"; current docs do **not** instruct configs to enable it | Absence is NOT a finding. If present, fine; note lazy.nvim enables an equivalent cache itself |

## Reasoned (mechanism-based, Low severity, label as such)

- **Synchronous process spawns at startup**: `vim.fn.system()` / `io.popen()` / `vim.system():wait()` executed unconditionally in `init.lua`-reachable code blocks startup for the child process duration. A bootstrap `git clone` guarded by an existence check is the standard pattern and fires once — not a finding.
- **Eager `require` of heavy plugin modules at top level** of always-loaded config files, when the plugin manager offers event/ft/cmd-gated loading and the module is only needed on those events.
- **Per-event work that could be one-shot**: expensive callbacks on high-frequency events (`CursorMoved`, `TextChanged`, `WinScrolled`) doing redundant computation; missing `once = true` on run-once autocmds.
- **Groupless autocmds in re-sourceable files**: duplicates accumulate on every re-source, multiplying callback cost (`:h lua-guide-autocommands-group` — the `clear = true` group pattern exists exactly for this).
- **Unused providers**: `vim.g.loaded_python3_provider = 0` etc. (`:h provider`) skips provider detection. The perf framing is community lore — mention only as an optional note, never as a violation.
- **Startup-deferral via `vim.schedule`/`vim.defer_fn`**: a community idiom, not an official recommendation. Do not demand it; do not flag its presence.

## Measurement guidance (include in the report when relevant)

Recommend — but do not run — these; they launch Neovim and write files, which is outside this skill's read-only contract:

```
nvim --startuptime /tmp/startup.log +q     # :h --startuptime — per-step timing
nvim --clean                               # bisect config vs defaults (:h --clean, :h bisect)
```

Also relevant: lazy.nvim users can inspect `:Lazy profile`. Present measurement as the user's follow-up step for any startup finding that is reasoned rather than documented.

## What NOT to flag

- `vim.opt` vs `vim.o` — no documented performance difference; choosing either is style, not perf.
- `vim.cmd()` string calls — no documented overhead claim; flag only under the Modern API lens as an idiom/consistency note when a Lua API exists.
- A plugin manager's own bootstrap block (one-shot, guarded).
- Lazy-loading that is absent for _light_ modules — deferral has complexity cost too; only heavy, measurable modules justify a finding.
