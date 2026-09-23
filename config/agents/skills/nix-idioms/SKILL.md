---
name: nix-idioms
description: "Guides Nix implementation, refactoring, review, and modernization of Nix expressions, flakes, packages, overlays, and NixOS, Home Manager, and nix-darwin modules using official practices compatible with the project's pinned Nix and nixpkgs versions."
---

# Nix Idioms (Nix-version- and nixpkgs-release-aware)

Authority sources: the Nix Reference Manual (language, builtins, `nix` CLI, release notes), nix.dev guides (Best practices, module system tutorial), the Nixpkgs manual (stdenv, meta, fetchers, overlays, trivial builders), the NixOS manual and release notes, the Nixpkgs release notes, `pkgs/README.md`, `pkgs/by-name/README.md`, `CONTRIBUTING.md`, RFC 140 (`pkgs/by-name`), RFC 166 (official formatter), and the Home Manager and nix-darwin manuals. Do not invent recommendations: every idiom below traces to one of these sources. Community linters (`statix`, `deadnix`) and blog posts are not authorities; cite them only as tooling.

## Step 0: Resolve the project baseline (ALWAYS first)

Nix has two independent version axes plus an evaluation mode. Before writing or recommending any Nix code:

1. **Evaluator version**: run `nix --version` (in a read-only review, or when it cannot be invoked, use `nix.package` in the NixOS/nix-darwin config or the CI image and say so). Note the implementation: CppNix (`nix (Nix) X.Y.Z`), Lix, or Determinate Nix each ship different experimental-feature defaults; the catalog below is written against CppNix.
2. **nixpkgs revision**: read the pin, in this order of evidence — `flake.lock` (`nodes.nixpkgs.original.ref`, e.g. `nixos-26.05` or `nixpkgs-unstable`, plus `locked.lastModified`/`rev`), `npins`/`niv` sources files, a `builtins.fetchTarball` URL with a hash, or `nix-channel --list`. Map it to a release: a stable branch `nixos-YY.MM`/`release-YY.MM` is that release; `nixpkgs-unstable`/`nixos-unstable`/`master` is the *next* release in development, and date-tagged catalog entries apply when `lastModified` is at or after the entry's date. When the input is already fetched, the `.version` file in its store path (see Verification sources) or `nix eval --raw nixpkgs#lib.version` gives the exact `YY.MM[pre...]` string.
3. **Evaluation mode**: `flake.nix` present means pure evaluation (`pure-eval`): no `builtins.currentSystem`, `builtins.getEnv`, `<nixpkgs>` lookup paths, or `~/` path literals. `default.nix`/`shell.nix` without a pin means impure classic mode; treat lookup paths there as a finding, not a baseline.
4. **Module-system consumer** (when modules are involved): NixOS (`system.stateVersion`, a `YY.MM` string), Home Manager (`home.stateVersion`), nix-darwin (`system.stateVersion`, an integer). State versions gate stateful defaults only; they are never a language or lib baseline and must never be bumped as part of a modernization.
5. If nixpkgs is not pinned at all, treat the current stable release (the catalog coverage release below) as the working floor, prefer conservative choices, and suggest pinning (in reviews, tag it `[recommend]`). This suggestion is mandatory output, like the baseline statement.
6. **State the resolved baseline and its sources in the deliverable** (e.g. "Nix 2.35.1 from `nix --version`; nixpkgs `nixpkgs-unstable` locked 2026-09-21 in `flake.lock`, i.e. 26.11 pre-release; flakes, pure eval; Home Manager + nix-darwin") before emitting any code or findings. Silent resolution is non-compliance.

Hard rules derived from the baseline:

- **Never use a builtin, CLI form, lib function, or builder attribute introduced after the resolved Nix version or nixpkgs release.** When a catalog item is desirable but version-gated, present it as an option labeled with the required Nix version or nixpkgs release — do not silently use it. When writing code, record the gated option as a brief source comment at the first affected site and mention it, with the required version, in the summary to the user.
- **Never rely on an experimental feature the project has not enabled.** `nix-command`, `flakes`, `pipe-operators`, and `fetch-tree` are all still experimental in Nix 2.35.2; a flake project has enabled the first two, nothing more. Code that must evaluate inside nixpkgs or under another user's `nix.conf` must not use `|>`/`<|`.
- **Never raise a floor as a side effect**: a newer installed Nix does not authorize APIs above the pinned nixpkgs, and `nixpkgs-unstable` does not authorize Nix builtins above the installed evaluator. If an idiom cannot satisfy both axes, say which axis blocks it.
- If the project targets a release older than the catalog coverage release, items introduced later are migration options (`[gated-option]`), not violations; removed-construct findings still apply relative to the targeted release.
- When recommending a change in review, always cite the Nix version or nixpkgs release that removed, deprecated, or introduced the construct so it can be checked against the pin.

## Catalog coverage and verification

**Catalog coverage version: Nix 2.35.2 (2026-08-12) and Nixpkgs/NixOS 26.05 "Yarara" (2026-05-30), plus dated entries from nixpkgs master toward 26.11.** The catalogs below are verified against official sources up to this point. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the verification sources when — and only when:

- **Staleness guard**: the resolved Nix version is newer than 2.35.2, the pinned nixpkgs is a stable release newer than 26.05, or an unstable pin's `lastModified` is later than the newest dated entry in this file. The catalog is out of date for this project. Do both: (a) read the release notes for everything changed between the coverage point and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating (see Maintenance below).
- A construct or its introducing/removing version is **not listed here** AND is **boundary-relevant** — plausibly changed at or after nixpkgs 23.05 / Nix 2.18 (the catalog floor) or near the resolved baseline: never trust memory for nixpkgs alias and lib history; verify before gating on it. Long-established facilities that clearly predate the floor (`lib.optionals`, `lib.mkIf`, `stdenv.mkDerivation`, `builtins.map`) need no verification.
- A catalog entry **conflicts with observed evaluator behavior or the pinned nixpkgs source**: the pinned source wins; report the discrepancy. Distinguish a `warnAlias`/`lib.warn` (usable, deprecated), a `throw` alias (removed), and an absent attribute when checking history.

Verification sources, in order of preference:

1. **Pinned nixpkgs sources (local, prefer this)**: `nix flake archive --dry-run --json . | jq -r .inputs.nixpkgs.path` (already-fetched inputs resolve without network; `nix-instantiate --eval -E '<nixpkgs>'` in classic mode), then read `.version` there for the exact release and Read/Grep `pkgs/top-level/aliases.nix` (dated `# Added YYYY-MM-DD` comments on every alias), `lib/`, `pkgs/stdenv/generic/`, and `doc/`. A `warnAlias`/`lib.warn` wrapper means deprecated-but-usable; `throw` means removed.
2. Nix release notes: https://nix.dev/manual/nix/latest/release-notes/ (one page per version, `rl-2.XX.html`); language reference https://nix.dev/manual/nix/latest/language/ ; builtins https://nix.dev/manual/nix/latest/language/builtins.html ; experimental features https://nix.dev/manual/nix/latest/development/experimental-features.html
3. NixOS release notes https://nixos.org/manual/nixos/unstable/release-notes and Nixpkgs release notes (nixpkgs `doc/release-notes/rl-YYMM.section.md`, 25.05 onward); Nixpkgs manual https://nixos.org/manual/nixpkgs/unstable/
4. Conventions: https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md , https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/README.md , https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md , https://nix.dev/guides/best-practices
5. Module consumers: Home Manager release notes https://nix-community.github.io/home-manager/release-notes.xhtml ; nix-darwin CHANGELOG https://github.com/nix-darwin/nix-darwin/blob/master/CHANGELOG

**Verification fallback**: if a source is unreachable or a tool cannot be run (offline, sandboxed, restricted), try at most one alternate route, then stop and degrade: prefer a construct whose version is already catalog-listed; if none fits, state the recommendation with an explicit "unverified" label and the assumed version. Never let unreachable sources block the deliverable or trigger repeated fetch attempts.

## Maintenance (updating this skill for a new Nix or NixOS release)

When asked to update this skill after a release:

1. Read the Nix release notes for every version between the coverage version and the new one, and the NixOS + Nixpkgs release notes for every release between the coverage release and the new one (including "Backward Incompatibilities", "Nixpkgs Library", and "Other Notable Changes").
2. Promote dated master entries to their release tag once released; add newly removed constructs, newly deprecated aliases, and newly standardized facilities with their version tags.
3. Remove nothing that older pins may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".
5. **Floor raise** (only when both hold: SKILL.md is approaching ~300 lines, AND floor-end entries are old enough that virtually all maintained pins exceed them): move entries below the new floor — tags intact — to `references/archive.md`, bump the floor wherever it is stated, and amend the boundary-verification rule so the archive is consulted before fetching release notes.

## Write-mode output (writing or modifying code)

Writing code needs no report, but the deliverable summary must contain, in one place:

1. The resolved baseline and its sources (Step 0), and the pin suggestion when Step 0 item 5 applied.
2. Any version-gated option that was considered: a brief source comment at the first affected site, plus a mention with the required version in the summary.
3. What verification ran — `nix fmt`, `nix flake check --no-build` (add `--all-systems` when outputs are per-system), `nix eval`/`nix-instantiate --eval` on the touched attribute, `nix build` for a package or `nix run .#build`-style dry builds for a system configuration — or an explicit note that it was skipped and why. `nix flake check --no-build` evaluates but does not build; say so rather than claiming a build passed. Never run activation commands (`switch`, `nixos-rebuild switch`, `darwin-rebuild switch`, `home-manager switch`) or `nix flake update` unless the user explicitly asked in this conversation; they mutate the live system or the lock file.
4. Summary prose follows the conversation language; code, identifiers, and tags stay in English.

## Review output contract

When the task is a review or audit, structure the report as follows.

1. **Baseline statement first**: Nix version, nixpkgs pin and mapped release, evaluation mode, and module consumer, each with its source (Step 0).
2. **Findings**, each tagged with exactly one severity. Severity follows from the rule class, not executor judgment:
   - `[error]` — fails to evaluate or build on the resolved baseline: a `throw` alias or removed lib function relative to the pin (`lib.mdDoc` on 24.11+, `cargoSha256` on 25.05+, `lib.types.string` on 25.11+), an impure construct under pure evaluation (`<nixpkgs>`, `builtins.currentSystem`, `~/` paths in a flake), an experimental feature the project has not enabled, a hash-less fetch in pure mode, or a `phases`/`installPhase` override that drops `runHook` calls a hook depends on.
   - `[warn]` — evaluates but emits an official deprecation warning or violates a mandatory nixpkgs rule: `warnAlias`/`lib.warn` wrappers (`nixfmt-rfc-style` on 25.11+, `stdenv.isDarwin` on master ≥ 2026-05-09), `substituteInPlace --replace`, `lib.getExe` on a package without `meta.mainProgram`, `builtins.toPath`, deprecated flake default outputs, a `mkDerivation` custom phase missing `runHook`, `meta.description` violating the documented format.
   - `[recommend]` — legal but officially discouraged, or a catalog-listed modernization within the baseline: top-level `with`, `rec` where `let` or `finalAttrs` fits, `sha256 =` where `hash =` (SRI) is accepted, `rev = "v${version}"` where `tag` exists, `if cond then [ ] else [ ]` where `lib.optionals` fits, `self: super:` naming, `overrideDerivation`, `cleanSource`/`sourceByRegex` where `lib.fileset` fits. Explicitly distinguish "discouraged by an official source" from "optional modernization".
   - `[gated-option]` — desirable but above the pinned Nix version or nixpkgs release; must carry the required version and must never be presented as a direct fix.

   Severity is decided by the status of the construct the reviewed code actually uses on the resolved baseline; the status of the replacement appears only in the recommendation text, never as the finding's tag.

3. Every finding cites the authority it rests on: the Nix version or nixpkgs release that removed, deprecated, or introduced the construct, or — for version-independent guidance — the manual chapter, `pkgs/README.md` rule, `CONTRIBUTING.md` rule, or nix.dev best-practice section, so it can be checked against the baseline.
4. **Non-findings**: what was deliberately not reported — at minimum the formatting/style exclusion below when style-adjacent items are present.
5. Report prose follows the conversation language; code snippets, identifiers, and severity tags stay in English.
6. When one finding's fix supersedes another (e.g. moving a package to `finalAttrs` removes both the `rec` and the `version` duplication findings), report both and cross-reference which fix subsumes which.

Evaluating the reviewed expression to confirm a finding is optional corroboration, never required — the version-tagged catalog decides severity. If you do evaluate, use `nix eval`/`nix-instantiate --eval` with the project's own pin (never a different nixpkgs) and disclose any substitution.

## Language-level catalog (Nix evaluator, version-tagged)

Status belongs to the specific construct, not to a section heading.

- **Experimental features still experimental in Nix 2.35.2**: `nix-command`, `flakes` (both since 2.4, 2021-11-01), `fetch-tree` (`builtins.fetchTree`, split from `flakes` in 2.19), `pipe-operators` (`|>`, `<|`, 2.24). Code that must work under default `nix.conf` uses `nix-build`/`nix-shell`/`nix-instantiate` and no pipe operators; a flake project may assume `nix-command` and `flakes` only.
- **`builtins.toPath`** — documented as DEPRECATED; → `/. + "/path"` for absolute, `./. + "/path"` for relative paths.
- **Deprecated flake default outputs** (Nix 2.7): `defaultPackage.<system>` → `packages.<system>.default`; `defaultApp` → `apps.<system>.default`; `devShell.<system>` → `devShells.<system>.default`; `overlay` → `overlays.default`; `defaultTemplate` → `templates.default`; `defaultBundler` → `bundlers.<system>.default`. Still accepted, but `nix flake check` warns.
- **`nix flake lock --update-input <x>`** → `nix flake update <x>` (Nix 2.19). `nix flake lock` only adds missing entries and never updates existing ones — prefer it in scripts that must not bump pins.
- **`nix profile install`** → `nix profile add` (Nix 2.30; old name kept as alias). `nix profile` and `nix-env` must not be mixed on one profile (2.4 note: a profile touched by `nix profile` becomes incompatible with `nix-env`). Element names replaced indices in 2.20.
- **`nix hash to-*`** → `nix hash convert` (deprecated in 2.20). `builtins.convertHash` exists since 2.19; its `"base32"` format name is a deprecated alias of `"nix32"` since 2.24.
- **`__json` structured attrs** → `__structuredAttrs = true` (2.30 documents this as the proper form).
- **Newer builtins, gate on the evaluator**: `builtins.warn` (2.23), `builtins.readFileType` (2.14), `builtins.parseFlakeRef`/`flakeRefToString` (2.18, need `flakes`), `builtins.convertHash` (2.19), `builtins.groupBy` (2.5), `builtins.zipAttrsWith` (2.6), `builtins.floor`/`ceil` (2.4), `builtins.hashFile` (2.3). Nixpkgs 25.11+ itself requires Nix ≥ 2.18, so anything at or below 2.18 needs no gating on a 25.11+ pin.
- **Lint settings** (2.34): `lint-url-literals` (stabilised from `no-url-literals`), `lint-short-path-literals`, `lint-absolute-path-literals`; default `ignore`, may be `warn` or `fatal`. Recommend quoted URLs and `./`-prefixed relative paths regardless (see Best practices).
- **Import from derivation (IFD)**: reading a store path produced by a derivation during evaluation forces a build mid-evaluation; `allow-import-from-derivation = false` turns it into an error, `trace-import-from-derivation` (2.30) logs it. `pkgs/README.md` states IFD "is disallowed in Nixpkgs for performance reasons"; treat it as `[recommend]` elsewhere unless the project disallows it, then `[error]`.
- **`nixConfig` in `flake.nix`**: only `bash-prompt*`, `flake-registry`, and `commit-lock-file-summary` apply without confirmation; anything else (substituters, keys) needs `accept-flake-config` or an interactive prompt. Do not present `nixConfig` as a way to force settings on other users.
- **`inputs.self.submodules = true`** (2.27) for flakes that need Git submodules; relative-path inputs (2.26).

## Language idioms (official best practices, version-independent)

From https://nix.dev/guides/best-practices unless noted:

- **Quote URLs**; bare URL literals are a legacy syntax (`lint-url-literals`).
- **Avoid `rec`; use `let ... in`**: shadowing inside `rec` yields hard-to-debug `infinite recursion`. In `mkDerivation` arguments, use the `finalAttrs:` fixed point instead (see Packaging), because `rec` "works at the syntax level and is unaware of overriding" (Nixpkgs manual, stdenv).
- **No `with` at the top of a file**; for small scopes prefer `inherit (pkgs) curl jq;` in a `let`, or `builtins.attrValues { inherit (pkgs) curl jq; }`. `with` bindings never shadow explicit bindings (Nix manual, scope rules), which is exactly why static analysis and readers cannot tell where a name comes from.
- **No `<nixpkgs>` lookup paths outside minimal examples**: they resolve through `NIX_PATH`, so two machines evaluate different revisions. Pin explicitly (flake input, `npins`, `fetchTarball` with `sha256`).
- **Set `config` and `overlays` explicitly when importing nixpkgs** (`import nixpkgs { inherit system; config = { }; overlays = [ ]; }`); otherwise `~/.config/nixpkgs/` is read impurely. In flakes, `nixpkgs.legacyPackages.${system}` is the un-overlaid set; only `import nixpkgs { ... }` applies overlays or `config.allowUnfree`. `NIXPKGS_ALLOW_UNFREE=1` applies to channels and `<nixpkgs>` only; "Flakes ignore it; pass `config` directly" (Nixpkgs manual, configuration).
- **`//` is shallow**; use `lib.recursiveUpdate` for nested updates, and `lib.mkMerge` inside modules.
- **Reproducible source paths**: `src = ./.` names the store path after the working directory; use `builtins.path { path = ./.; name = "source"; }` or `lib.fileset.toSource` (nixpkgs 23.11+), which also selects files explicitly.
- **Purity**: `builtins.getEnv` "should be used with care" (manual); `builtins.currentTime`, `currentSystem`, `storePath`, and `nixPath` are unavailable under `pure-eval`. `--impure` is a debugging escape hatch, never a fix to recommend for a flake.
- **String context**: a store path becomes a build dependency only when the *derivation value* is interpolated (`"${pkg}/bin/x"`); `toString`ing a path or `builtins.unsafeDiscardStringContext` drops the dependency. Interpolating a *path literal* copies it into the store — intended for sources, a bug for `/etc` and home paths.
- From `CONTRIBUTING.md`: list function arguments precisely (`{ stdenv, fetchurl, perl }:` not `args: with args;` nor a catch-all `...`) so `callPackage` can check them; `lowerCamelCase` variables, kebab-case file names; build conditional lists with `lib.optional(s)`, not `if c then [ ] else [ ]` or `null`; write `{ tag = version; }` not `{ tag = "${version}"; }`.

## Nixpkgs removed and deprecated constructs (release-tagged)

Each entry is tagged with the release that deprecated (warning) and removed (throw or absent) it. The "not drop-in" notes state the required ripple.

- **`stdenv.lib`** (deprecated 21.05, removed 21.11) → `lib` (from the package's argument set) or `pkgs.lib`
- **`lib.types.string`** (warning 23.11, removed 25.11) → `lib.types.str` (not drop-in: `string` concatenated multiple definitions; `str` rejects them — use `types.lines` or `types.separatedString` where merging was relied on); `lib.types.loaOf` still exists only as a deprecated alias → `types.attrsOf`
- **`lib.literalExample`** (warning through 25.05, removed 25.11) → `lib.literalExpression` (or `lib.literalMD` for non-Nix text)
- **`lib.mdDoc`** (warning 24.05, removed 24.11): option descriptions are Markdown by default; delete the wrapper. **`lib.options.mkPackageOptionMD`** (obsolete 24.11) → `lib.mkPackageOption`
- **Nixpkgs lib removals in 25.11**: `lib.attrsets.cartesianProductOfSets` (→ `lib.cartesianProduct`, renamed 24.05), `lib.zipWithNames`, `lib.zip`, `lib.mapAttrsFlatten` (deprecated 24.11), `lib.replaceChars` (→ `lib.replaceStrings`), `lib.readPathsFromFile`, `lib.strings.isCoercibleToString`, `lib.modules.defaultPriority`
- **`lib.warn msg val`** (24.11): `msg` must now be a string, matching `builtins.warn`
- **`nixfmt-rfc-style`** (alias with warning since 2025-07-14, i.e. 25.11) → `nixfmt`; **`nixfmt-classic`** throws on master since 2026-07-01 (→ 26.11)
- **`substituteInPlace --replace`** (deprecated 24.05, still only warns) → `--replace-fail` (errors when nothing matched; the correct default), `--replace-warn`, `--replace-quiet`
- **`substituteAll` / `substituteAllFiles`** (deprecated 25.05) → `replaceVars` (not drop-in: variables are passed as an explicit attribute set, and unreplaced `@var@` placeholders are errors)
- **`rustPlatform.buildRustPackage` `cargoSha256`** (deprecated 24.11, removed 25.05) → `cargoHash` (SRI). 25.05 also switched the default vendoring to `fetchCargoVendor`, so every `cargoHash` changes on upgrade; pins that must stay compatible with 24.11 set `useFetchCargoVendor = true` explicitly
- **`buildGoModule` `vendorSha256`** (deprecated 23.11, ignored 24.05) → `vendorHash`, which must be given explicitly (24.05+; `null` when there are no dependencies). **`buildGoPackage`** (deprecated 24.11, removed 25.05) → `buildGoModule`. **`CGO_ENABLED` at top level** → `env.CGO_ENABLED` (25.05; compatibility layer removed 25.11). `buildGoModule` accepts `finalAttrs:` since 25.05
- **`buildPythonPackage` `format`** → `pyproject = true` (23.11) with `build-system` and `dependencies` (24.05) instead of `nativeBuildInputs`/`propagatedBuildInputs`; since 25.11 an explicit format is required (the implicit `setup.py` default is gone), and passing `stdenv` to it is deprecated. **`pytestFlagsArray`/`unittestFlagsArray`** → `pytestFlags`/`unittestFlags` (25.05; error in 26.05)
- **`env` must be an attribute set** (25.11)
- **`stdenv.isDarwin`, `stdenv.isLinux`, `stdenv.isAarch64`, `stdenv.isx86_64`, `stdenv.is64bit`, …** → `stdenv.hostPlatform.isX` — deprecation warning added on master 2026-05-09 (→ 26.11), gated on `config.allowAliases`, so with `allowAliases = false` the old names do not exist at all. No warning through 26.05: `[recommend]` on ≤ 26.05 pins, `[warn]` on unstable pins at or after that date
- **`pie` hardening flag** (deprecated 25.11, removed 26.05). **`xorg` package set** deprecated (26.05; packages moved to top level). **`nodePackages`** removed (26.05)
- **`x86_64-darwin`**: 26.05 is the last release supporting it (warning; `allowDeprecatedx86_64Darwin`); dropped on master (→ 26.11). Treat new Darwin-specific code as `aarch64-darwin` unless the project still pins ≤ 26.05
- **`nixos-rebuild`**: `nixos-rebuild-ng` default since 25.11 (`system.rebuild.enableNg` must be removed on 26.05), Bash implementation removed 26.05; alias `nixos-rebuild = nixos-rebuild-ng` since 2025-12-02
- **`lib.nixosSystem` / `eval-config.nix` `extraArgs` and `check`** (deprecated since 2021, removed on master → 26.11) → `config._module.args` and `config._module.check = false`; the `system` argument is deprecated in favor of `nixpkgs.hostPlatform`, and `pkgs` in favor of `nixpkgs.pkgs`
- **MD5 hashes** rejected by `mkDerivation` (23.11); **minimum Nix for nixpkgs** raised to 2.18 (25.11)
- **Home Manager / nix-darwin**: `services.nix-daemon.enable` removed (nix-darwin, 2025-01-29; `nix.enable` toggles Nix management); user-level activation options removed and `system.primaryUser` required for user-scoped options (2025-01-30); `homebrew.brewPrefix` → `homebrew.prefix` (2026-02-10). Home Manager 26.05 changes (e.g. `programs.zsh.dotDir` defaulting to XDG) apply only when `home.stateVersion` ≥ "26.05"

## Modern facilities to prefer (introduced in or before coverage)

These are modernization choices, not claims that their predecessors are deprecated unless the section above says so.

- **`finalAttrs:` fixed point** (nixpkgs 22.05): `stdenv.mkDerivation (finalAttrs: { pname = ...; version = ...; src = fetchFromGitHub { tag = "v${finalAttrs.version}"; ... }; })`; `overrideAttrs (finalAttrs: previousAttrs: { ... })`. `overrideDerivation` is explicitly discouraged ("prefer `overrideAttrs` in almost all cases"). `buildEnv` takes `finalAttrs` since 25.11
- **`hash = "sha256-..."` (SRI)** instead of `sha256 = "<base32>"` — "It is recommended that you use the `hash` attribute" (Nixpkgs manual, fetchers). Placeholder must be `""`, `lib.fakeHash`, `lib.fakeSha256`, or `lib.fakeSha512`, never an arbitrary hash (a wrong-but-real hash silently reuses an existing store object). Convert with `nix hash convert --hash-algo sha256 <hex>` (Nix 2.20+)
- **`fetchFromGitHub { tag = version; }`** instead of `rev = "v${version}"` or `rev = "refs/tags/..."` (master since 2024-12-05, i.e. 25.05; verify the 24.11 backport in the pinned source before using it there). `fetchzip`/`fetchFromGitHub` strip the top-level directory so hashes survive re-tarring; `fetchurl` is for single files; `fetchpatch2` for patches already merged upstream, with a comment naming the upstream PR
- **`pkgs/by-name/<xx>/<name>/package.nix`** (RFC 140; introduced 23.11, enforced for new `pkgs.callPackage` packages 24.05): the file must not read outside its directory; custom `callPackage` arguments still live in `all-packages.nix`. Out-of-tree projects may mirror the layout with `lib.packagesFromDirectoryRecursive`
- **`lib.fileset`** (23.11): `lib.fileset.toSource { root = ./.; fileset = lib.fileset.unions [ ./src ./Cargo.toml ]; }` instead of `lib.cleanSource`/`lib.sourceByRegex`; `lib.fileset.fromSource` migrates gradually. File sets cannot represent empty directories
- **`meta.mainProgram`** (mandatory for packages with a primary executable, `pkgs/README.md`) and **`lib.getExe pkg`** (22.05; warns without `mainProgram` since 23.11) / **`lib.getExe' pkg "name"`** instead of `"${pkg}/bin/name"`. Changing `mainProgram` rebuilds the package since 25.11 (`NIX_MAIN_PROGRAM`)
- **`meta` hygiene** (Nixpkgs manual, meta; `pkgs/README.md`): `description` one sentence, capitalized, no article, no package name, no trailing period ("Library for decoding PNG images"); `homepage`, `license` from `lib.licenses` (`lib.licenses.unfree` when unclear), `maintainers`, `platforms`, `changelog`, `sourceProvenance` for binary packages
- **`pname` + `version`** (lowercase `pname` equal to the upstream name; `version` starts with a digit; `"X.Y-unstable-YYYY-MM-DD"` for unreleased commits) instead of a combined `name`
- **Dependency placement**: build-time tools (`cmake`, `pkg-config`, `makeWrapper`, `installShellFiles`) in `nativeBuildInputs`; libraries linked or needed at runtime in `buildInputs`; add `strictDeps = true` (default only in the language-specific builders) so misplacement fails instead of working by accident
- **Phases**: never set `phases`; override `xxxPhase` and begin/end it with `runHook preXxx` / `runHook postXxx`, otherwise `preInstall`/`postInstall` hooks are silently skipped. Use `install -Dm755` / `installBin` / `installManPage` / `installShellCompletion --cmd`; `wrapProgram` with `--prefix PATH : ${lib.makeBinPath [ ... ]}`
- **`env = { FOO = "bar"; }`** (23.05) for exported environment variables; **`__structuredAttrs = true`** is "the preferred default" and required for new top-level nixpkgs packages (manual, stdenv); it makes `passAsFile` unnecessary, and disables `allowedReferences`-family checks unless `outputChecks` is used
- **Tests**: `doCheck = true` with `nativeCheckInputs`; `doInstallCheck = true` + `versionCheckHook` in `nativeInstallCheckInputs` (24.11); `passthru.tests` (`nix build .#pkg.tests`); `passthru.updateScript = nix-update-script { }`
- **`writeShellApplication { name; runtimeInputs; text; }`** (21.11) instead of `writeScriptBin`/`writeShellScriptBin` for anything non-trivial: adds `set -o errexit -o nounset -o pipefail`, runs `shellcheck` and `bash -n`, and puts `runtimeInputs` on `PATH`. `runCommand` uses `stdenvNoCC`; `runCommandLocal` only for sub-second commands. `symlinkJoin`/`linkFarm` for composing outputs
- **Overlays**: `final: prev:` (the manual's current naming; `self: super:` is "older code"); take dependencies from `final`, override from `prev`; `prev.pkg.overrideAttrs` for build changes, `prev.pkg.override` for `callPackage` argument changes
- **Warnings and errors in expressions**: `lib.warn`/`lib.warnIf`/`lib.throwIf`/`lib.assertMsg` (or `builtins.warn`, Nix 2.23) instead of `builtins.trace` strings and bare `assert`
- Do NOT recommend `pipe-operators`, `lib.pipe` rewrites, or `__structuredAttrs` migrations proactively in out-of-tree projects; mention them only when the code already uses the feature incorrectly or the user asks

## Module-system idioms (NixOS, Home Manager, nix-darwin)

- Module shape `{ config, lib, pkgs, ... }: { imports = [ ]; options = { }; config = { }; }`. Once a module has a top-level `options` or `config` key, every definition must live under `config`; a stray key errors with "has an unsupported attribute".
- **`lib.mkIf cond { ... }`, never `if cond then { ... } else { }` on a whole definition set**: the condition usually reads `config.*`, and a plain `if` makes the attribute *names* depend on the value being built (infinite recursion). `mkIf` pushes the condition into each option definition. Combine sets with `lib.mkMerge [ ... ]`.
- **Priorities**: option default 1500 (`mkOptionDefault`), `mkDefault` = `mkOverride 1000`, plain definition 100, `mkForce` = `mkOverride 50` — lower wins. Order: `mkBefore` (500), default 1000, `mkAfter` (1500). Modules meant to be overridden by users set defaults with `mkDefault`.
- **`lib.mkOption { type; default; description; example; }`**: `type` is mandatory in nixpkgs; `description` is Markdown (no `mdDoc`); `defaultText`/`literalExpression` when the default is not renderable. `lib.mkEnableOption "x"`, `lib.mkPackageOption pkgs "x" { }`.
- **Types**: `str` (single definition), `lines` (concatenated), `singleLineStr`, `listOf` (concatenated), `attrsOf` (joined), `nullOr`, `enum`, `package` (prefer over `path` for store paths), `submodule`/`submoduleWith` (the submodule receives `name` and `config`), `port`. `types.attrs` warns that it will be deprecated (no recursion, ignores `mkDefault`/`mkIf`) → `submodule`, `attrsOf`, or `anything`.
- **Renames**: `lib.mkRenamedOptionModule`, `mkRemovedOptionModule`, `mkAliasOptionModule`, `mkChangedOptionModule` in `imports`, never silent breakage. **`assertions`** (`{ assertion; message; }`) and **`warnings`** instead of `abort`/`builtins.trace`.
- **Arguments**: `_module.args` for values modules may define; `specialArgs`/`extraSpecialArgs` (Home Manager) only for what `imports` must see (they cannot be overridden by modules). Home Manager's `config.lib.file.mkOutOfStoreSymlink` for live-editable dotfiles.
- **State versions**: NixOS `system.stateVersion` "does not affect the Nixpkgs version your packages and OS are pulled from" and "Most users should never change this value after the initial install"; Home Manager `home.stateVersion` selects stateful defaults; nix-darwin `system.stateVersion` is an integer (max 7 as of 2026-05). Never bump one in a modernization; flag a bump that lacks a migration note as `[warn]`.
- Platform conditionals: `lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ ... ]` and `lib.optionalAttrs`; never `builtins.currentSystem` in a module.

## Flake idioms

- Outputs that `nix flake check` inspects: `checks.<system>.<name>`, `packages.<system>.{default,<name>}`, `devShells.<system>.{default,<name>}`, `apps.<system>.{default,<name>}` (`{ type = "app"; program = lib.getExe pkg; }`), `nixosConfigurations.<name>` (built via `config.system.build.toplevel`), `overlays.{default,<name>}`, `nixosModules.{default,<name>}`, `templates`, `bundlers`, `hydraJobs`, `legacyPackages`; `formatter.<system>` is what `nix fmt` runs. `darwinConfigurations` and `homeConfigurations` are consumer conventions (nix-darwin, Home Manager), not checked by Nix itself.
- Per-system outputs via `lib.genAttrs systems (system: ...)` (`forAllSystems`) or `flake-parts`; `flake-utils` is a third-party convenience, not an authority.
- `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"` to deduplicate nixpkgs; `nix flake update <input>` (2.19) for a single input; `nix flake lock` adds missing entries only.
- `nix flake check --no-build --all-systems` evaluates every configuration without building (what CI typically runs); `nix flake show` lists outputs; `nix build .#pkg -L` shows build logs; `nix eval --raw .#x` inspects values; `nix repl .#` (2.22+) loads the flake.
- Flakes evaluate only git-tracked files: a new file is invisible until `git add` (report "path does not exist" errors in that light); `?dir=`/relative inputs (2.26) for subflakes.

## Official style and formatting

- **`nixfmt`** (RFC 166) is the official formatter: 2-space indent, 100-column soft limit, idempotent output; nixpkgs CI enforces it and the tree was reformatted for 25.05. Run `nix fmt` (via the flake's `formatter`) or `nixfmt` directly rather than hand-formatting; when it cannot be run, match its output manually and say so. Do not use `nixfmt-classic` (throws on master).
- Formatting and naming beyond `CONTRIBUTING.md` ("Any style choices not covered here ... should be left at the discretion of the authors of changes and not commented in reviews") are **not findings**; the only naming rules are `lowerCamelCase` variables, lowercase `pname`, kebab-case file names, and `pkgs.<attr>` matching `pname` (leading digit → `_` prefix).
- Commit summaries in nixpkgs style: `pkgname: 1.0 -> 1.1`, `pkgname: init at 1.0`, `nixos/module: fix ...`, no trailing period.
- `statix`, `deadnix`, `nil`/`nixd` are community tools; `nixpkgs-vet` is the official CI check for `pkgs/by-name`. Cite them as tooling, never as the authority for a finding.
