#!/usr/bin/env bash
set -uo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
. "$root/tests/lib.sh"
scan="$root/skills/macos-disk-cleanup/agent/skills/cleaning-dev-build-artifacts/scan.sh"

t_exit "scan requires a root" 1 bash "$scan"

tmp="$(mktemp -d)"
busy_pid=""
trap '[ -n "$busy_pid" ] && { kill "$busy_pid"; wait "$busy_pid"; } 2>/dev/null; rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
dev="$tmp/dev"
app="$dev/app"
wt="$app/.claude/worktrees"

git init -q --bare "$tmp/remote.git"
git clone -q "$tmp/remote.git" "$app" 2>/dev/null
echo a > "$app/f"
echo target/ > "$app/.gitignore"
git -C "$app" add f .gitignore
git -C "$app" commit -q -m init
git -C "$app" push -q origin HEAD:main
git -C "$app" fetch -q
# Hides untracked files from a plain `git status`; the scan must still see them.
git -C "$app" config status.showUntrackedFiles no

for w in pushed local dirty cache fakecache untracked corrupt busy; do
  git -C "$app" worktree add -q --detach "$wt/$w" origin/main
done
git -C "$wt/local" commit -q --allow-empty -m local
echo b > "$wt/dirty/f"
mkdir "$wt/cache/.cache" && printf 'Signature: 8a477f597d28d172789f06886806bc55\n' > "$wt/cache/.cache/CACHEDIR.TAG"
mkdir "$wt/fakecache/gen" && touch "$wt/fakecache/gen/CACHEDIR.TAG" "$wt/fakecache/gen/main.rs"
echo new > "$wt/untracked/new.txt"
echo garbage > "$(git -C "$wt/corrupt" rev-parse --git-path index)"
(cd "$wt/busy" && exec sleep 60) &
busy_pid=$!

# gh stub: prints "#N STATE OID" for the branch named by --head.
mkdir -p "$tmp/bin" "$tmp/gh"
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do [ "$1" = --head ] && { cat "$GH_STUB/$2" 2>/dev/null; exit 0; }; shift; done
EOF
chmod +x "$tmp/bin/gh"
for b in merged ahead open; do
  git -C "$app" worktree add -q -b "$b" "$wt/$b" origin/main
  git -C "$wt/$b" commit -q --allow-empty -m "$b"
done
echo "#1 MERGED $(git -C "$wt/merged" rev-parse HEAD)" > "$tmp/gh/merged"
echo "#2 MERGED $(git -C "$wt/ahead" rev-parse HEAD)" > "$tmp/gh/ahead"
git -C "$wt/ahead" commit -q --allow-empty -m after-merge
touch "$wt/open/Cargo.toml" && mkdir "$wt/open/target"
git -C "$wt/open" add Cargo.toml
git -C "$wt/open" commit -q -m crate
echo "#3 OPEN $(git -C "$wt/open" rev-parse HEAD)" > "$tmp/gh/open"

# Rust crates: pinned in place, pinned by a parent dir, and unpinned.
arch="$(uname -m | sed 's/^arm64$/aarch64/')-apple-darwin"
mkdir -p "$dev/pinned/target" "$dev/mono/crates/inner/target" "$dev/plain/target" \
  "$tmp/home/.rustup/toolchains/1.99.0-$arch/bin"
touch "$dev/pinned/Cargo.toml" "$dev/mono/crates/inner/Cargo.toml" "$dev/plain/Cargo.toml"
printf '[toolchain]\nchannel = "1.99.0"\n' > "$dev/pinned/rust-toolchain.toml"
printf '[toolchain]\nchannel = "1.99.0"\n' > "$dev/mono/rust-toolchain.toml"
install -m 755 /dev/null "$tmp/home/.rustup/toolchains/1.99.0-$arch/bin/cargo"

(cd "$tmp" && HOME="$tmp/home" PATH="$tmp/bin:$PATH" GH_STUB="$tmp/gh" bash "$scan" "$dev") > "$tmp/out" 2>&1
show() { cat "$tmp/out"; }

t_out "detached HEAD on a remote branch is removed" 'REMOVE\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/pushed\n' show
t_out "detached HEAD on no remote branch is kept" 'KEEP\(detached HEAD is on no remote branch\)\s+detached \w+ on=no-remote\s*\n\s+\S+/worktrees/local\n' show
t_out "uncommitted change is kept" 'KEEP\(1 uncommitted change\(s\)\)\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/dirty\n' show
t_out "tagged cache dir is not uncommitted work" 'REMOVE\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/cache\n' show
t_out "CACHEDIR.TAG without the signature is work" 'KEEP\(1 uncommitted change\(s\)\)\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/fakecache\n' show
t_out "untracked file hidden by config is kept" 'KEEP\(1 uncommitted change\(s\)\)\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/untracked\n' show
t_out "failed git status is kept" 'KEEP\(git status failed\)\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/corrupt\n' show
t_out "worktree with a process inside is kept" 'KEEP\(in use by: sleep\s*\)\s+detached \w+ on=origin/main\s*\n\s+\S+/worktrees/busy\n' show
t_out "merged PR at the worktree HEAD is removed" 'REMOVE\s+branch=merged pr=#1 MERGED' show
t_out "commits after the merged PR head are kept" 'KEEP\(HEAD has commits after the merged PR head\)\s+branch=ahead pr=#2 MERGED' show
t_out "open PR is kept" 'KEEP\(PR is OPEN\)\s+branch=open pr=#3 OPEN' show
t_out "pinned crate gets its toolchain's cargo" "\S+/pinned\s*\n\s+cargo=\S+/toolchains/1\.99\.0-$arch/bin/cargo" show
t_out "crate inherits a parent dir's pin" "\S+/crates/inner\s*\n\s+cargo=\S+/toolchains/1\.99\.0-$arch/bin/cargo" show
t_out "unpinned crate falls back to stable" "\S+/plain\s*\n\s+cargo=\S+/toolchains/stable-$arch/bin/cargo" show
t_no_out "worktree target dirs are not listed as crates" '/worktrees/\S+\s*\n\s+cargo=' show

t_done disk-cleanup
