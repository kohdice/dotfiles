---
name: nvim-config-review
description: This skill should be used when the user asks to review a Neovim configuration — "review my nvim config", "check my Neovim setup", "Neovim の設定をレビューして", "nvim 設定が古くないか確認して", "非推奨 API を探して" — or to audit Lua config files under a Neovim config directory. It reviews modern API usage, deprecations, performance, and configuration layout against the resolved target version, using a version-tagged catalog with centralized coverage and update guidance. It is read-only, never edits files, and never launches Neovim except `nvim --version`. Do not use it for general Lua code review or plugin development; it reviews configurations only.
---

# Neovim Config Review

Review a Neovim configuration against the official recommendations for its resolved target version, and report findings without modifying anything. The version-tagged catalog lives in `references/`; its coverage is defined once below and is not the review target or a claim about the latest stable release.

## Catalog coverage and verification

**Catalog coverage version: Neovim 0.12.3.** Catalog snapshot: 2026-07. This is the single source of truth for coverage across this skill and its references. Versions attached to individual features, deprecations, and removals are historical compatibility boundaries; keep them when updating coverage.

- **Within coverage**: use the catalog as the default checklist, gated by the resolved target. Verify findings as required by the Principles below; do not re-derive the entire catalog on every review.
- **Beyond coverage**: when the resolved target is newer, check official release notes and version-matched runtime docs for changes between coverage and the target, including intervening patch releases. Apply verified changes to this review and tell the user the catalog needs updating. Do not silently cap the review at coverage or edit this skill during a review.
- **Development builds**: preserve the full prerelease version and commit when known. A development series beyond coverage also triggers the check above, but is not a released stable version. Use docs from that build's commit when available; otherwise disclose that verification is incomplete.
- **Latest stable requests**: resolve "latest stable" from https://github.com/neovim/neovim/releases/latest and record the concrete tag. Never infer it from the catalog, `master`, `nightly`, or the unversioned website. Discovering a newer stable release does not override a project's target unless the user asks to review for that release.
- **Unavailable evidence**: if a source fails, try at most one alternate official route, then complete the review with the available evidence. If already known to be offline, skip fetches. Label unresolved version-dependent claims **unverified**, keep them out of confirmed findings, and state the coverage limit. Do not invent changes, imply a complete review of newer versions, or block the report on downloads.

## Maintenance (updating this skill for a new stable Neovim)

When asked to update the catalog:

1. Resolve the latest stable tag from the official releases page above (or use the release explicitly requested). A newer tag alone does not establish catalog coverage.
2. Read the release notes and relevant `runtime/doc/news*.txt`, `deprecated.txt`, and runtime source changes for every release between coverage and the requested version, including patch releases. Separate API introduction, deprecation, and actual removal.
3. Update the affected lens references with their exact compatibility boundaries and official sources. Retain entries needed by older targets; do not globally replace version numbers. Recheck mutable claims such as plugin archive status and development-branch removals before retaining them as verified facts.
4. Only after verification, update the coverage version and snapshot date in this section's preceding coverage block. Reference files link to that block instead of duplicating the snapshot. If verification is incomplete, retain the previous coverage and report the gap.

## Principles

- **Read-only**: Never edit files, never mutate git state, never launch Neovim to "test" the config (`nvim --headless` writes logs, caches, and lazy-lock state). The only permitted executable check is `nvim --version` — run it as `NVIM_LOG_FILE=/dev/null nvim --version`, since in sandboxed environments a bare invocation drops a stray `nvim.log` into the working directory. This principle outranks anything in `references/` (e.g. a detection command that would launch Neovim is recommended to the user, never run).
- **Official sources only**: A finding must trace to Neovim's own documentation (`:h` pages published at neovim.io/doc, `runtime/doc/deprecated.txt`, `runtime/doc/news.txt`) or a plugin's own repository (archived status, README deprecation notice). Blog posts and popular opinion do not justify findings.
- **Version-anchored**: Resolve the target using workflow step 1 before reviewing. Do not flag an API as deprecated for a version older than its deprecation, and do not recommend features the target version lacks. These gates and the verification requirements override reference tables and severity labels.
- **Verify before reporting**: The tables in `references/` are a snapshot. Load-bearing findings — every High, anything marked UNVERIFIED, and any claim that cannot be traced to a `:h` tag — must be confirmed before reporting; a Medium already confirmed in the target version's own `deprecated.txt` needs no further check. Prefer (1) local runtime docs only when their version matches the target, (2) https://raw.githubusercontent.com/neovim/neovim/v<target>/runtime/doc/ (substitute the exact stable version; use a commit for development builds). If only a release series is known, `release-<major>.<minor>` is a moving fallback: record the ref and uncertainty about patch-specific behavior. Unversioned neovim.io/doc pages are discovery aids, not proof of availability in an older target. Plugin status must be checked in the plugin's own repository; if relevant, check the pinned plugin revision too. Apply the bounded fallback in Catalog coverage and verification when sources are unavailable.
- **One report**: Synthesize all findings into a single report in the conversation language. Code, identifiers, and paths stay in English.

## Workflow

1. **Resolve scope and version.** Default scope is the Neovim config directory in the current repository (e.g. `config/nvim/`) or `~/.config/nvim` when not in a dotfiles repo; a user-named path overrides both. If the scope contains no `init.lua`/`init.vim`, say so and stop. Resolve the target in this order:
   - An explicit user-requested version, including a verified latest stable request, wins.
   - Otherwise, a repository pin managing Neovim (e.g. `.tool-versions` or a Nix flake) wins over the installed binary. For an indirect pin such as `flake.lock`, use an already available resolved version or matching binary; never build, install, or update dependencies to resolve it. An unrelated installed binary is not evidence of the pin's version.
   - Without a repository pin, use `NVIM_LOG_FILE=/dev/null nvim --version` if available.
   - If the target cannot be resolved, state **target unknown**, continue version-independent checks, and make version-dependent advice conditional with its required version. Do not substitute the catalog or latest stable as an assumed target.

   Open the report with the target, its source, and the catalog coverage. Note any known discrepancy between the pin and installed binary. Apply the coverage check above before reviewing.

2. **Inventory the config.** Map the directory tree: entry point, `lua/` modules, `plugin/`, `after/`, `ftplugin/`, `lsp/` or `after/lsp/`, plugin manager and its spec files, lockfiles. Build the plugin list from the specs (and lockfile if present).

3. **Review the four lenses**, loading the matching reference file for each:

   | Lens         | Question                                                                                                                        | Reference                       |
   | ------------ | ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
   | Modern API   | Does the config use officially recommended mechanisms available in the target version (native LSP config, Lua APIs, built-ins)? | `references/modern-patterns.md` |
   | Deprecations | Does any code call deprecated/removed APIs, or depend on archived/superseded plugins?                                           | `references/deprecated-apis.md` |
   | Performance  | Does anything slow startup or runtime (eager loading, synchronous work at startup, per-event waste)?                            | `references/performance.md`     |
   | Architecture | Are responsibilities separated per module, and does the layout follow the runtimepath conventions `:h lua-guide` describes?     | `references/architecture.md`    |

   For a small config, run the lenses inline in one pass. For a large config (roughly 25+ Lua files — count every `*.lua` under the scope recursively, including `after/`, `ftplugin/`, and `lsp/`; near the threshold either mode is acceptable), dispatch one sub-agent per lens in parallel. Sub-agent contract:
   - Use a read-only agent type (no Edit/Write tools) and restate the read-only rule in its prompt, including that it must not launch Neovim at all — the parent resolves the target version once and passes it in.
   - Give each sub-agent the scope path plus a file listing (exact paths for the files its lens must read; directory granularity is fine for grep-only coverage), the resolved target and source, catalog coverage and any verified newer changes or verification limits, and its lens's reference file path.
   - Each sub-agent returns findings — as `path:line`, evidence, official replacement, and source, the same shape step 5 reports — plus coverage notes: which files it only grepped versus read, and which claims it left unverified. Step 5's coverage summary is assembled from these notes.
   - The parent reads each lens's reference file too, before synthesizing — step 5's severity arbitration relies on them.

4. **Grep systematically, then read.** Deprecated-API detection is grep-shaped: search the scope for each pattern in the deprecation tables before reading files one by one. Reading is for confirming context (a match inside a comment or a pinned-old-version guard is not a finding).

5. **Synthesize.** Dedup findings by `(path, line)`, group by severity, and report:
   - **High** — errors or breaks on the target version or a verified next-release development revision: removed API, archived/deleted plugin requiring migration, circular `require`. For future breakage, cite the revision and distinguish it from a current error; a scheduled removal or an old claim about `master` is not proof.
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

- **`references/deprecated-apis.md`** — Version-tagged deprecated/removed Lua APIs with replacements and grep patterns; plugins superseded by built-ins.
- **`references/modern-patterns.md`** — Version-tagged official mechanisms: `vim.lsp.config()`/`vim.lsp.enable()` and the `lsp/` runtimepath directory, `vim.pack` status, keymap/option/autocmd idioms.
- **`references/performance.md`** — Startup and runtime performance checklist with detection commands.
- **`references/architecture.md`** — Officially documented directory layout, runtimepath semantics, and separation-of-concerns heuristics.
