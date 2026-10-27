# macos-disk-cleanup

For developers whose Mac keeps filling up with build output and caches. macOS only.

## What it is

Two skills for when the disk is nearly full:

- `cleaning-dev-build-artifacts` clears build output: Rust `target/` dirs and the worktrees Claude Code opens. It ships a read-only scan script, `scan.sh`, that marks each worktree `REMOVE` or `KEEP` and names the toolchain's cargo to clean each `target/` with.
- `cleaning-dev-caches` clears caches that can be downloaded again: Homebrew, the package managers, Gradle, Playwright browsers, Edge and VS Code update leftovers, stale simulator dyld caches, Rust toolchains nothing pins.

## Why

Most of the space you can reclaim in one piece sits in these places, and all of it can be rebuilt; the cost is a slower next build or download. The hard part is knowing whether something is safe to delete right now: a worktree may hold uncommitted changes or local commits made after its PR merged, a cache may be in use by a running process, and the simulator dyld cache for the current OS build comes straight back after deletion, freeing nothing. The two skills turn each of these into a check, skip any item that fails it, and say why. When a permission check blocks a deletion, the agent does not route around it; it hands you the command to run yourself.

## How to use it

Say "my disk is full", "clean build artifacts" or "clear caches", and the agent loads the matching skill from its description. It scans before deleting and reports what each item freed. Personal data such as cloud-sync folders, Downloads, Desktop and photo libraries is listed, never deleted.

## What gets installed

Skills `cleaning-dev-build-artifacts` (with `scan.sh`) and `cleaning-dev-caches`, in the skills directory you chose. The placeholder `DEV_ROOT` is the directory that holds your repositories, default `~/dev`. Both skills act on the whole machine, so user level is the better fit.

## Dependencies

macOS and `git`; `gh` to check whether a branch's PR has merged. Any other command in the tables (brew, pnpm, rustup, xcrun and so on) that is not installed just skips its row.
