---
name: cleaning-dev-build-artifacts
description: Use when this Mac's disk is nearly full, or the user asks to clean build output — Rust target/ dirs or Claude Code worktrees (.claude/worktrees) under {{DEV_ROOT}} (「清编译产物」「清 target」「清 worktree」「硬盘满了」, "clean build artifacts"). Not for package-manager or app caches (cleaning-dev-caches) or personal files.
---

# Clean build output

Most of the space you can reclaim in one piece under {{DEV_ROOT}} sits in two places: Rust `target/` dirs, and the worktrees Claude Code opens (each Rust worktree carries a full `target/` of its own, each web worktree its own `node_modules`). Both can be rebuilt; the only cost is a slower next build.

## 1. Scan (read-only)

```bash
bash <this skill's directory>/scan.sh {{DEV_ROOT}}
```

Output: one line per worktree, `REMOVE` or `KEEP(<reason>)`, with the path of its main repository; one line per `target/` with its size and the cargo of that repository's pinned toolchain, marked `BUSY` when cargo or rustc is running inside it.

## 2. Worktrees: remove only those marked REMOVE

The scan says REMOVE when the worktree has no uncommitted changes (untracked dirs carrying `CACHEDIR.TAG` are tool caches and do not count), no process has its cwd inside it, and one of these holds:
- On a branch: the branch's PR is MERGED, and the worktree HEAD equals the PR's head commit (no local commits after the merge).
- Detached HEAD: HEAD is on some remote branch.

```bash
git -C <main> worktree remove --force <worktree path>
git -C <main> worktree prune
```

`--force` is there only to take the gitignored `target/` and `node_modules` along; uncommitted changes were already ruled out. Leave everything marked KEEP and list the reasons for the user.

When a permission check or classifier blocks a deletion, do not retry it in another form. Finish the other items first, then hand the full command to the user to run themselves (in Claude Code: `! <command>`).

## 3. target/: cargo clean with the pinned toolchain

```bash
<cargo path from the scan> clean --manifest-path <repo>/Cargo.toml
```

- Call `~/.rustup/toolchains/<channel>-<arch>/bin/cargo` directly; do not depend on a `cargo` on PATH.
- Not `rm -rf target`: classifiers block it, and do not route around them with another way of deleting.
- Skip anything marked BUSY and tell the user to clean it after the build finishes.

## 4. Wrap up

Run `df -h /System/Volumes/Data` again and report free space before and after, plus what each item reclaimed.

## Out of scope

- `node_modules` and `.next` in main repositories: in daily use.
- Package-manager, browser and updater caches, unused Rust toolchains: use cleaning-dev-caches.
- Cloud-sync folders, Downloads, Desktop, chat histories, photo / TV / music libraries: personal data. List them, never delete.
