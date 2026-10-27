---
name: cleaning-dev-caches
description: Use when this Mac's disk is nearly full, or the user asks to clear re-downloadable caches (「清缓存」「硬盘满了」, "clear caches") — Homebrew, npm / pnpm / yarn / bun / uv / pip, Gradle, Playwright browsers, Edge and VS Code updater caches, simulator dyld caches, unused Rust toolchains. Not for build output (cleaning-dev-build-artifacts) or personal files.
---

# Clear caches

Everything in the table below is downloaded or rebuilt again the next time it is needed. Before deleting, confirm one thing only: the program that owns it is not using it right now.

Before starting, record free space with `df -h /System/Volumes/Data`, and record each item's size with `du -sh` before deleting it. Skip any row whose command does not exist.

| Cache | Extra precondition | Command |
|---|---|---|
| Homebrew downloads and old versions | none | `brew cleanup -s --prune=all` |
| npm | none | `npm cache clean --force` |
| npx packages | `pgrep -f _npx` is empty (MCP servers started by npx run from here) | `rm -rf ~/.npm/_npx`; `npm cache clean` does not touch this directory |
| pnpm store | none | `pnpm store prune` |
| bun | run it in a directory with a `package.json`, otherwise it deletes nothing | `(cd <any JS repo> && bun pm cache rm)` |
| yarn / uv / pip | none | `yarn cache clean` / `uv cache clean` / `pip3 cache purge` |
| Gradle | `pgrep -f GradleDaemon` is empty | `rm -rf ~/.gradle/caches` |
| Playwright browsers | no e2e run in progress | `rm -rf ~/Library/Caches/ms-playwright ~/Library/Caches/ms-playwright-go`; tell the user to run `npx playwright install` before the next e2e run |
| Microsoft Edge | `pgrep -x "Microsoft Edge"` is empty | `rm -rf ~/Library/Caches/Microsoft\ Edge` |
| VS Code update leftovers | VS Code is closed | `rm -rf ~/Library/Caches/com.microsoft.VSCode.ShipIt` |
| Simulator dyld cache | stale ones only, see below | `xcrun simctl runtime dyld_shared_cache remove <runtime>` |
| Unused Rust toolchains | `pgrep -x cargo` and `pgrep -x rustc` are empty; keep list below | `rustup toolchain uninstall <name>` |

**Simulator dyld cache**: `/Library/Developer/CoreSimulator/Caches/dyld/<host build>/<runtime>/`. A cache is stale only when its host build differs from `sw_vers -buildVersion` or its runtime is no longer in `xcrun simctl runtime list`. Deleting the current one reclaims nothing: the next simulator launch rebuilds it as it was.

**Rust toolchains**: keep `stable`, the default (`rustup default`), every directory override (`rustup override list`), custom toolchains linked with `rustup toolchain link` (they are not re-downloadable), `*-sbpf-solana-*` (installed by Solana's build tools), and every channel pinned in a `rust-toolchain` or `rust-toolchain.toml` anywhere under {{DEV_ROOT}}. The rest of `~/.rustup/toolchains` can be uninstalled.

When a precondition fails (Edge is open, say), skip that row and tell the user at the end how to clear it later. When a permission check or classifier blocks an `rm -rf`, do not route around it; hand the command to the user to run themselves (in Claude Code: `! <command>`).

## Keep, do not touch

- `~/.claude/projects`: Claude Code's session transcripts; usage tools such as ccusage read them.
- The conda installation itself (for example `/opt/homebrew/Caskroom/miniconda`): projects run their environments from it.
- Installed iOS simulator runtimes: projects run their tests on them.
- No need for `conda clean -a`: packages are hard-linked into the environments, so it reclaims almost nothing.

## Wrap up

Run `df -h /System/Volumes/Data` again and report what each item reclaimed, which items were skipped and why, and free space before and after.
