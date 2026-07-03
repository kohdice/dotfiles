---
name: nvim-config-review
description: This skill should be used when the user asks to review a Neovim configuration — "review my nvim config", "check my Neovim setup", "Neovim の設定をレビューして", "nvim 設定が古くないか確認して", "非推奨 API を探して" — or to audit Lua config files under a Neovim config directory. It reviews four dimensions against the target Neovim version's official recommendations (knowledge snapshot: 0.12): (1) modern API usage, (2) deprecated APIs and superseded plugins, (3) startup/runtime performance, (4) separation of concerns and the officially recommended directory layout. It is read-only, never edits files, and never launches Neovim except `nvim --version`. Do not use it for general Lua code review or plugin development; it reviews configurations only.
---

# Neovim Config Review

Review a Neovim configuration against the implementation practices officially recommended for Neovim 0.12, and report findings without modifying anything. The knowledge snapshot lives in `references/`; treat it as the checklist, and verify anything uncertain against live official docs before reporting it.

## Principles

- **Read-only**: Never edit files, never mutate git state, never launch Neovim to "test" the config (`nvim --headless` writes logs, caches, and lazy-lock state). The only permitted executable check is `nvim --version` — run it as `NVIM_LOG_FILE=/dev/null nvim --version`, since in sandboxed environments a bare invocation drops a stray `nvim.log` into the working directory. This principle outranks anything in `references/` (e.g. a detection command that would launch Neovim is recommended to the user, never run).
- **Official sources only**: A finding must trace to Neovim's own documentation (`:h` pages published at neovim.io/doc, `runtime/doc/deprecated.txt`, `runtime/doc/news.txt`) or a plugin's own repository (archived status, README deprecation notice). Blog posts and popular opinion do not justify findings.
- **Version-anchored**: Determine the target Neovim version first (`nvim --version`; fall back to reading version pins in the repo, e.g. a Nix flake). Do not flag an API as deprecated for a version older than its deprecation, and do not recommend features the target version lacks.
- **Verify before reporting**: The tables in `references/` are a snapshot. Load-bearing findings — every High, anything the reference marks UNVERIFIED, and any claim that cannot be traced to a `:h` tag — must be confirmed against official docs before reporting; a Medium already confirmed in the target version's own `deprecated.txt` needs no further check. Equivalent official sources, in order of reliability here: (1) the locally installed Neovim runtime docs (`runtime/doc/deprecated.txt` etc. next to the `nvim` binary — read the files directly, no Neovim launch needed), (2) `raw.githubusercontent.com/neovim/neovim/release-<target>/runtime/doc/...`, (3) deepwiki on neovim/neovim, (4) WebFetch on neovim.io/doc (often fails to return content — do not retry more than once, fall back instead). Plugin status: WebFetch the plugin's GitHub repo page (archive banner, README notice) — prefer this over `gh api`/`curl`, which sandboxed environments often block.
- **One report**: Synthesize all findings into a single report in the conversation language. Code, identifiers, and paths stay in English.

## Workflow

1. **Resolve scope and version.** Default scope is the Neovim config directory in the current repository (e.g. `config/nvim/`) or `~/.config/nvim` when not in a dotfiles repo; a user-named path overrides both. Record the target version: when the repo containing the scope manages the Neovim binary itself (e.g. a Nix flake), that pin states the config's intent and wins — for an indirect pin with no readable version literal (flake.lock), the version of the binary it resolves to is the pin. Otherwise use `nvim --version`. If pin and installed binary differ, use the pin and note the discrepancy in the report. If the scope contains no `init.lua`/`init.vim`, say so and stop.

2. **Inventory the config.** Map the directory tree: entry point, `lua/` modules, `plugin/`, `after/`, `ftplugin/`, `lsp/` or `after/lsp/`, plugin manager and its spec files, lockfiles. Build the plugin list from the specs (and lockfile if present).

3. **Review the four lenses**, loading the matching reference file for each:

   | Lens         | Question                                                                                                                    | Reference                       |
   | ------------ | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
   | Modern API   | Does the config use the mechanisms 0.12 recommends (native LSP config, current Lua APIs, built-in features over plugins)?   | `references/modern-patterns.md` |
   | Deprecations | Does any code call deprecated/removed APIs, or depend on archived/superseded plugins?                                       | `references/deprecated-apis.md` |
   | Performance  | Does anything slow startup or runtime (eager loading, synchronous work at startup, per-event waste)?                        | `references/performance.md`     |
   | Architecture | Are responsibilities separated per module, and does the layout follow the runtimepath conventions `:h lua-guide` describes? | `references/architecture.md`    |

   For a small config, run the lenses inline in one pass. For a large config (roughly 25+ Lua files — count every `*.lua` under the scope recursively, including `after/`, `ftplugin/`, and `lsp/`; near the threshold either mode is acceptable), dispatch one sub-agent per lens in parallel. Sub-agent contract:
   - Use a read-only agent type (no Edit/Write tools) and restate the read-only rule in its prompt, including that it must not launch Neovim at all — the parent resolves the target version once and passes it in.
   - Give each sub-agent the scope path plus a file listing (exact paths for the files its lens must read; directory granularity is fine for grep-only coverage), the target version, and its lens's reference file path.
   - Each sub-agent returns findings — as `path:line`, evidence, official replacement, and source, the same shape step 5 reports — plus coverage notes: which files it only grepped versus read, and which claims it left unverified. Step 5's coverage summary is assembled from these notes.
   - The parent reads each lens's reference file too, before synthesizing — step 5's severity arbitration relies on them.

4. **Grep systematically, then read.** Deprecated-API detection is grep-shaped: search the scope for each pattern in the deprecation tables before reading files one by one. Reading is for confirming context (a match inside a comment or a pinned-old-version guard is not a finding).

5. **Synthesize.** Dedup findings by `(path, line)`, group by severity, and report:
   - **High** — errors or breaks on the target version or the next release: removed API, archived/deleted plugin requiring migration, circular `require`
   - **Medium** — works today but degrades correctness or maintainability: deprecated API with a working replacement, load-order-sensitive side effects, measurable startup cost
   - **Low** — style drift from official recommendations, advisory structure improvements

   Each lens reference refines severity within this rubric; when this rubric and a reference disagree, the reference file wins. When two references assign different severities to the same finding, the lens that owns the finding's mechanism wins (deprecation status → `deprecated-apis.md`, official idiom → `modern-patterns.md`, runtime cost → `performance.md`, structure → `architecture.md`); the other lens's mention is supplementary context, not a second finding.

   Every finding needs `path:line`, evidence (the offending code), the official replacement, and the source (`:h` tag or URL). For reasoned performance findings about third-party plugins — where no `:h` tag can exist — cite the plugin's own docs/repo URL and label the claim reasoned, as `performance.md` defines; that satisfies this requirement. End with a coverage summary: lenses run, files skipped, and claims that remain unverified.

6. **Recommend, do not act.** The report may propose exact fixes, but applying them is a separate, user-approved task outside this skill.

## Red flags (watch for rationalizations)

| Rationalization                                     | Reality                                                                                            |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| "This plugin is unpopular now, so flag it."         | Popularity is not deprecation. Flag only archived repos, README notices, or built-in replacements. |
| "Run nvim headless to confirm the config loads."    | Out of scope. It writes state. Confirm by reading code.                                            |
| "The deprecation table says so, no need to verify." | The table is a snapshot; verify load-bearing findings against live docs.                           |
| "lazy.nvim exists, so vim.pack must replace it."    | Check the reference: coexistence is legitimate; report the trade-off, not a mandate.               |
| "I'll fix this one-liner while I'm here."           | Read-only. Report it; fixing is a follow-up task.                                                  |

## Additional Resources

### Reference Files

- **`references/deprecated-apis.md`** — Deprecated/removed Lua APIs (0.10–0.12) with replacements and grep patterns; plugins superseded by built-ins.
- **`references/modern-patterns.md`** — 0.12-recommended implementations: `vim.lsp.config()`/`vim.lsp.enable()` and the `lsp/` runtimepath directory, `vim.pack` status, keymap/option/autocmd idioms.
- **`references/performance.md`** — Startup and runtime performance checklist with detection commands.
- **`references/architecture.md`** — Officially documented directory layout, runtimepath semantics, and separation-of-concerns heuristics.
