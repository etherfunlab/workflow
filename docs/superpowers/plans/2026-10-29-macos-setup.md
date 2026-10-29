# macOS Setup Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A one-line `install.sh` that turns a fresh Apple Silicon Mac into the maintainer's shell environment (Homebrew, oh-my-zsh + powerlevel10k, brew zsh plugins, iTerm2 with font and colors, miniconda, Claude Code, Codex, VS Code, Grok CLI), with a jsDelivr/USTC mirror mode for weak networks.

**Architecture:** One bash script `setup/macos/install.sh` made of ten `step_*` functions over a small output/log layer; three template files next to it that the script copies into `$HOME`. A stub-driven test suite runs the whole script against a temporary HOME with fake `brew`, `curl`, `git`, `defaults` and friends on PATH, so no test ever touches the real machine.

**Tech Stack:** bash 3.2 (the `/bin/bash` macOS ships; no associative arrays, no `mapfile`), zsh for the template syntax check, python3 only in tests (stdlib), the repo's `tests/lib.sh` helpers.

**Spec:** `docs/superpowers/specs/2026-10-29-macos-setup-design.md`

## Global Constraints

- Everything under `setup/` and `tests/` is English; no product names, private repo names, internal URLs, local absolute paths (anything under a real home directory), emails or tokens anywhere, commit messages included (AGENTS.md).
- Commits: Conventional Commits, English. One PR for the whole plan; run `tests/run-all.sh` before each commit.
- `install.sh` runs under `/bin/bash` (bash 3.2) with `set -euo pipefail`; every external command is called by bare name (never `/usr/bin/uname`) so tests can stub it. The only absolute program path is `/bin/bash`; every other path goes through `$BREW_PREFIX`, `$APPS_DIR`, `$HOME` or a `SETUP_*` override.
- Never run `install.sh` against the real `$HOME`; tests always set `HOME` to a temp dir and run with `PATH=<stubs>:/usr/bin:/bin` only, so the maintainer's real `/opt/homebrew/bin` tools (and real `defaults`) are never reached.
- Homebrew mirror is USTC because its installer is a single curl-able file (`misc/brew-install.sh`); TUNA's needs `git clone`, and a fresh Mac has no git before CLT.
- Template values are copied from the maintainer's machine read-only (`~/.zshrc`, `~/.p10k.zsh`, the iTerm2 plist); nothing in `$HOME` is modified.
- Paths in templates are `/opt/homebrew` literally; `$HOME` is spelled `$HOME`, never a user name.
- Output: ANSI 16 colors + bold + dim only, disabled when stdout is not a tty or `NO_COLOR` is set; messages in English; style A from the spec (`==>` banners, status words `ok done skip adopt FAIL`).
- Pinned constants in `install.sh`: `P10K_COMMIT=d05a1b00f9a61f9578bf9dc19b8451942dde8734`; `REPO_RAW=https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos`; `REPO_CDN=https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos`; mirror values `HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git`, `HOMEBREW_API_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/api`, `HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles`, brew installer mirror `https://mirrors.ustc.edu.cn/misc/brew-install.sh`, omz installer mirror `https://install.ohmyz.sh/`, omz clone fallback `https://gitee.com/mirrors/oh-my-zsh.git`.

## Review Focus

1. A run interrupted mid-step (Ctrl-C during `brew install`) and re-run: every step must re-check state rather than trust a marker; test "second run changes nothing" in Task 6 covers the clean case, and Task 5's "failed cask retried on rerun" covers the interrupted case.
2. `~/.zprofile` that already contains a `brew shellenv` line with different spacing or quoting: the script must match on `brew shellenv`, not the exact line, or it appends a duplicate (Task 6 test "shellenv line already present with different quoting").
3. `SETUP_MIRROR` set to something other than `jsdelivr`: must exit with a message before touching anything (Task 2 test).
4. `curl` serving a jsDelivr listing that is truncated or not JSON (CDN error page with HTTP 200): p10k install must fail cleanly with no partial directory (Task 4 test "bad listing leaves no p10k dir").
5. A `.zshrc` already identical to the template but with a trailing newline difference from an editor: byte comparison says "different" and makes a backup; acceptable, but the summary must list the backup so the person sees it (Task 6 test "backup path appears in summary").

---

### Task 1: Templates

**Files:**
- Create: `setup/macos/zshrc`
- Create: `setup/macos/p10k.zsh`
- Create: `setup/macos/iterm2-profile.json`
- Create: `tests/setup-macos/run.sh` (template checks only; later tasks append)

**Interfaces:**
- Produces: the three template file names above, which `install.sh` (Task 2) fetches by basename; the iTerm2 profile's `"Guid"` value `9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11` and `"Name": "workflow"`, which Task 6 reads from the JSON.

- [ ] **Step 1: Write the template tests**

`tests/setup-macos/run.sh` starts like every suite (`set -uo pipefail`, `root=`, `. "$root/tests/lib.sh"`), defines `setup="$root/setup/macos"` and `real_home=$HOME` (captured before any test overrides `HOME`; the suite never spells out a home path, because the repo's pre-push denylist rejects one), and ends with `t_done setup-macos`. Tests:

```bash
t_exit "zshrc parses" 0 zsh -n "$setup/zshrc"
t_exit "p10k.zsh parses" 0 zsh -n "$setup/p10k.zsh"
t_exit "iterm2 profile is JSON" 0 python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$setup/iterm2-profile.json"
t_out "profile has the fixed guid" '"Guid": *"9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11"' cat "$setup/iterm2-profile.json"
t_out "profile names the font" '"Normal Font": *"MesloLGS-NF-Regular 15"' cat "$setup/iterm2-profile.json"
t_true "no home paths under setup/" bash -c '! grep -rnF "$2" "$1"' _ "$setup" "$real_home"
t_out "zshrc sources syntax highlighting last" 'zsh-syntax-highlighting\.zsh\s*$' tail -n 1 "$setup/zshrc"
t_out "zshrc puts fpath before oh-my-zsh" 'fpath=\(.*\n(.*\n)*source \$ZSH/oh-my-zsh\.sh' cat "$setup/zshrc"
t_no_out "zshrc has no supabase line" 'SUPABASE' cat "$setup/zshrc"
```

- [ ] **Step 2: Run the suite, expect every test to fail (files missing)**

Run: `bash tests/setup-macos/run.sh`
Expected: `setup-macos: 0 passed, 9 failed`

- [ ] **Step 3: Write `setup/macos/zshrc`**

Follow the spec's twelve-item order exactly. Content comes from the maintainer's `~/.zshrc` (read-only): keep the p10k instant-prompt block, `ZSH`, `ZSH_THEME`, `plugins=(git)`, the conda lazy block verbatim, the Homebrew / Claude Code / toolchain exports, `PATH="$HOME/.grok/bin:$PATH"`. Add `fpath=(~/.grok/completions/zsh /opt/homebrew/share/zsh-completions $fpath)` before `source $ZSH/oh-my-zsh.sh`; add `source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh` after the p10k source; move `source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh` to the last line. Replace the absolute pnpm path with `$HOME/Library/pnpm`. Drop every commented-out omz option and the Supabase line. Each kept non-obvious line gets one English comment line saying why; no dates.

- [ ] **Step 4: Copy `~/.p10k.zsh` to `setup/macos/p10k.zsh`**

Run: `cp ~/.p10k.zsh setup/macos/p10k.zsh` then `grep -cF "$HOME" setup/macos/p10k.zsh` → `0`.

- [ ] **Step 5: Generate `setup/macos/iterm2-profile.json` from the plist**

Read `~/Library/Preferences/com.googlecode.iterm2.plist` with `python3 -c` and `plistlib` (read-only), take the profile whose `Guid` equals the plist's `Default Bookmark Guid`, and emit:

```json
{ "Profiles": [ {
  "Guid": "9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11",
  "Name": "workflow",
  "Normal Font": "MesloLGS-NF-Regular 15",
  "Draw Powerline Glyphs": true,
  "Ansi 0 Color": { ...copied... }, ... "Ansi 15 Color": { ... },
  "Foreground Color", "Background Color", "Bold Color", "Cursor Color", "Cursor Text Color",
  "Cursor Guide Color", "Selection Color", "Selected Text Color", "Link Color": { ...copied... }
} ] }
```

Color dicts are copied whole (including `"Color Space"` and alpha), 2-space indent, keys sorted. Nothing else from the plist.

- [ ] **Step 6: Run the suite, expect all green**

Run: `bash tests/setup-macos/run.sh`
Expected: `setup-macos: 9 passed, 0 failed`

- [ ] **Step 7: Commit**

```bash
git add setup/macos/zshrc setup/macos/p10k.zsh setup/macos/iterm2-profile.json tests/setup-macos/run.sh
git commit -m "feat(setup): zshrc, p10k and iTerm2 profile templates for macOS"
```

---

### Task 2: Script skeleton, output layer, preflight, stubs

**Files:**
- Create: `setup/macos/install.sh`
- Create: `tests/setup-macos/stubs/{uname,sw_vers,id,sudo,xcode-select,softwareupdate,curl,git,brew,defaults,pgrep}`
- Create: `tests/setup-macos/http/` (fixtures served by the curl stub)
- Modify: `tests/setup-macos/run.sh`

**Interfaces:**
- Produces, in `install.sh`:
  - globals `SETUP_MIRROR` (env, `""` or `jsdelivr`), `BREW_PREFIX="${SETUP_BREW_PREFIX:-/opt/homebrew}"`, `APPS_DIR="${SETUP_APPS_DIR:-/Applications}"`, `LOG="${SETUP_LOG:-$HOME/.setup-macos/$(date +%Y%m%d-%H%M%S).log}"`, `TOTAL=10`, counters `N_DONE N_SKIP N_ADOPT`, array `LEFT_IN_PLACE`.
  - `say_banner <n> <title>`; `say_item <desc> <status> [seconds]` (status ∈ `ok done skip adopt FAIL`, bumps the matching counter); `say_notice <text>` (yellow); `say_fail <headline>` (red bold headline, last 3 log lines prefixed `│`, `Full log:` line, rerun hint, then `exit 1`).
  - `run <cmd...>`: appends `+ <cmd...>` and then the command's stdout+stderr to `$LOG`, returns its exit code (callers decide).
  - `timer_start` / `timer_secs` → seconds since `timer_start`; `say_item` prints the time only when ≥ 5 s, formatted `MmSSs` (`4m10s`).
  - `template_url <basename>` → `$REPO_RAW/<basename>` or `$REPO_CDN/<basename>` in mirror mode; `fetch_template <basename> <dest>` copies `$(dirname "${BASH_SOURCE[0]}")/<basename>` when `BASH_SOURCE[0]` is non-empty and that file exists, else curls `template_url`. (Under `bash -c "$(curl …)"` `BASH_SOURCE[0]` is empty, so a stray `zshrc` in the current directory is never picked up.)
  - `CLT_FLAG="${SETUP_CLT_FLAG:-/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress}"` (Task 3).
  - `main`: validates `SETUP_MIRROR`, runs `step_preflight`, then (Task 6) `prepare_dotfiles`, then the remaining nine steps in order, then `summary`.
- Produces, in stubs: every stub appends `"$(basename "$0") $*"` to `$STUB_LOG`; `curl` writes the fixture `$STUB_HTTP/<url with ':' and '/' replaced by '_'>` to stdout or to the `-o` target and exits 22 when no fixture exists; `uname -m` prints `${STUB_ARCH:-arm64}`, `uname -s` prints `Darwin`; `sw_vers -productVersion` prints `27.0.1`; `id -u` prints `${STUB_UID:-501}`; `sudo` runs its arguments (`-v` and `-n true` are no-ops); `xcode-select -p` prints `$STUB_CLT` when that file exists, else exits 2; `softwareupdate -l` prints `* Label: Command Line Tools for Xcode-27.0`, `-i` touches `$STUB_CLT`; `git clone <url> <dir>` makes `<dir>/.git` unless `<url>` matches the glob `$STUB_GIT_FAIL`; `brew` keeps installed names in `$STUB_BREW_STATE` (one per line, casks prefixed `cask:`), `list --cask|--formula <n>` exits 1 when absent, `install` appends and creates `$SETUP_BREW_PREFIX/bin/<name>` (exit 1 when `<name>` is in `$STUB_BREW_FAIL`, unless `--force` was passed and `<name>` is in `$STUB_BREW_FORCE_OK`), `uninstall` removes, `shellenv` prints `export PATH="$SETUP_BREW_PREFIX/bin:$PATH"`; `defaults` only logs; `pgrep -x iTerm2` exits 0 iff `STUB_ITERM_RUNNING=1`.
- Produces, in `run.sh`: `STUB_DIR=$root/tests/setup-macos/stubs`; `fresh()` makes a temp HOME, empties `$STUB_BREW_STATE`/`$STUB_LOG`, unsets every `STUB_*`/`SETUP_*` knob except the ones below, and exports `HOME SETUP_BREW_PREFIX=$tmp/brew SETUP_APPS_DIR=$tmp/apps SETUP_LOG=$tmp/setup.log SETUP_CLT_FLAG=$tmp/clt-flag STUB_CLT=$tmp/clt STUB_HTTP=$tmp/http STUB_DIR`; `install()` runs `PATH="$STUB_DIR:${EXTRA_PATH:+$EXTRA_PATH:}/usr/bin:/bin" bash "$setup/install.sh"` (the function name shadows `/usr/bin/install`, which `run.sh` never needs); `install_piped()` runs the script the way the start line does, `(cd "$tmp" && PATH="$STUB_DIR:/usr/bin:/bin" bash -c "$(cat "$setup/install.sh")")`, so `BASH_SOURCE[0]` is empty and templates come through the curl stub; `run.sh` therefore copies `tests/setup-macos/http/*` into `$tmp/http` (which is what `STUB_HTTP` points at) and adds the three templates there under both their `REPO_RAW` and `REPO_CDN` fixture names. `calls()` cats `$STUB_LOG`. Knobs are passed as prefix assignments (`STUB_ARCH=x86_64 t_exit … install`), never through `env`, because `install` is a shell function.

- [ ] **Step 1: Write the tests**

```bash
fresh; STUB_ARCH=x86_64 t_exit "intel mac exits 1" 1 install
t_true "intel mac wrote nothing" test ! -e "$HOME/.zshrc" -a ! -e "$HOME/.setup-macos"
fresh; STUB_UID=0 t_exit "root exits 1" 1 install
fresh; SETUP_MIRROR=bogus t_exit "unknown mirror exits 1" 1 install
SETUP_MIRROR=bogus t_out "unknown mirror says why" 'SETUP_MIRROR must be empty or jsdelivr' install
fresh; t_no_out "no color codes when piped" '\x1b\[' install
fresh; t_out "preflight banner" '==> \[ 1/10\] Preflight\n\s+macOS 27\.0\.1, arm64, not root\s+ok' install
```

(`install` is captured by `t_out`, so stdout is never a tty.)

- [ ] **Step 2: Run, expect the new tests to fail**

Run: `bash tests/setup-macos/run.sh`
Expected: the Task 1 tests pass; every new test fails with `install.sh: No such file`.

- [ ] **Step 3: Write the stubs and fixtures**

One file per stub as specified in Interfaces, `chmod +x`. Fixtures in `tests/setup-macos/http/` (they run in the script's environment, so they use the exported `SETUP_BREW_PREFIX` and `STUB_DIR`):

- Homebrew installer, under both `https___raw.githubusercontent.com_Homebrew_install_HEAD_install.sh` and `https___mirrors.ustc.edu.cn_misc_brew-install.sh`: `mkdir -p "$SETUP_BREW_PREFIX/bin" "$SETUP_BREW_PREFIX/share/zsh"; chmod 775 "$SETUP_BREW_PREFIX/share"; printf '#!/bin/sh\nexec "%s/brew" "$@"\n' "$STUB_DIR" > "$SETUP_BREW_PREFIX/bin/brew"; chmod +x "$SETUP_BREW_PREFIX/bin/brew"`.
- omz installer, under both `https___raw.githubusercontent.com_ohmyzsh_ohmyzsh_master_tools_install.sh` and `https___install.ohmyz.sh_`: `url=${REMOTE:-https://github.com/ohmyzsh/ohmyzsh.git}; case "$url" in ${STUB_GIT_FAIL:-^}) exit 1;; esac; mkdir -p "$HOME/.oh-my-zsh/.git" "$HOME/.oh-my-zsh/custom/themes"`.
- p10k listing for `@d05a1b00f9a61f9578bf9dc19b8451942dde8734?structure=flat`, in jsDelivr's shape including the top-level package name: `{"type":"gh","name":"romkatv/powerlevel10k","version":"d05a…","files":[{"name":"/powerlevel10k.zsh-theme","hash":"x","size":1},{"name":"/internal/p10k.zsh","hash":"x","size":1},{"name":"/gitstatus/install","hash":"x","size":1}]}`, plus the three file bodies (one line each).
- Grok installer `https___x.ai_cli_install.sh`: `mkdir -p "$HOME/.grok/bin"; printf '#!/bin/sh\n' > "$HOME/.grok/bin/grok"; chmod +x "$HOME/.grok/bin/grok"; printf '\n# >>> grok installer >>>\nexport PATH="$HOME/.grok/bin:$PATH"\n' >> "$HOME/.zshrc"` (it edits `.zshrc` the way the real one does).

- [ ] **Step 4: Write `install.sh` through preflight**

Header comment (what it does, the two start lines, what `SETUP_MIRROR` changes), constants, output layer, `run`, timers, `fetch_template`, `step_preflight`: exits 1 with a one-line reason when `uname -s` ≠ `Darwin`, `uname -m` ≠ `arm64`, or `id -u` = `0`; then `mkdir -p "$(dirname "$LOG")"`, `sudo -v`, a background `while true; do sudo -n true; sleep 50; done` loop killed on EXIT, and the `ok` item line with `sw_vers -productVersion`. `main` calls only `step_preflight` for now and the mirror validation (`case "$SETUP_MIRROR" in ""|jsdelivr) ;; *) echo "SETUP_MIRROR must be empty or jsdelivr" >&2; exit 1;; esac`) before anything else.

- [ ] **Step 5: Run, expect all tests except the banner test to pass**

Run: `bash tests/setup-macos/run.sh`
Expected: only "preflight banner" may still fail if later steps are missing; everything else passes. Also `bash -n setup/macos/install.sh` exits 0.

- [ ] **Step 6: Commit**

```bash
git add setup/macos/install.sh tests/setup-macos
git commit -m "feat(setup): install.sh skeleton with output layer, preflight and test stubs"
```

---

### Task 3: Command Line Tools and Homebrew

**Files:**
- Modify: `setup/macos/install.sh`
- Modify: `tests/setup-macos/run.sh`

**Interfaces:**
- Consumes: `run`, `say_*`, `BREW_PREFIX`, `SETUP_MIRROR`, curl/xcode-select/softwareupdate stubs.
- Produces: `step_clt`, `step_homebrew`, `brew_env` (exports the three USTC `HOMEBREW_*` values in mirror mode, each only if currently unset, and `NONINTERACTIVE=1`), and after `step_homebrew` the shell has `eval "$("$BREW_PREFIX/bin/brew" shellenv)"` applied so later steps call `brew` by name.

- [ ] **Step 1: Write the tests**

```bash
fresh; install >/dev/null; t_out "clt installed headless" 'softwareupdate -i Command Line Tools for Xcode-27\.0' calls
t_no_out "no gui clt prompt" 'xcode-select --install' calls
fresh; export STUB_CLT=$tmp/clt; touch "$STUB_CLT"; t_out "clt present is skipped" '\[ 2/10\] Xcode Command Line Tools\n\s+already installed\s+skip' install; unset STUB_CLT
fresh; install >/dev/null; t_out "default mode uses github installer" 'curl .*raw\.githubusercontent\.com/Homebrew/install/HEAD/install\.sh' calls
t_no_out "default mode touches no mirror" 'mirrors\.ustc\.edu\.cn' calls
fresh; SETUP_MIRROR=jsdelivr install >/dev/null; t_out "mirror mode uses ustc installer" 'curl .*mirrors\.ustc\.edu\.cn/misc/brew-install\.sh' calls
fresh; SETUP_MIRROR=jsdelivr HOMEBREW_BOTTLE_DOMAIN=https://example.test/b install >/dev/null
t_out "preset HOMEBREW var wins" 'HOMEBREW_BOTTLE_DOMAIN=https://example\.test/b' cat "$SETUP_LOG"
fresh; mkdir -p "$SETUP_BREW_PREFIX/bin"; cp "$STUB_DIR/brew" "$SETUP_BREW_PREFIX/bin/brew"; t_out "brew present is skipped" '\[ 3/10\] Homebrew\n\s+already installed\s+skip' install
```

(`step_homebrew` writes `env | grep ^HOMEBREW_` to the log after `brew_env`, which is what the preset test reads.)

- [ ] **Step 2: Run, expect the new tests to fail**

Run: `bash tests/setup-macos/run.sh` → the eight new tests fail.

- [ ] **Step 3: Implement `step_clt` and `step_homebrew`**

`step_clt`: skip when `xcode-select -p` succeeds; else `touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress`, pick the last `Command Line Tools for Xcode-*` label from `softwareupdate -l`, `run softwareupdate -i "$label"`, remove the touch file, `FAIL` when no label or non-zero exit. `step_homebrew`: skip when `$BREW_PREFIX/bin/brew` is executable; else `brew_env`, `run /bin/bash -c "$(curl -fsSL "$url")"` with the URL by mode, `FAIL` on non-zero; then `eval shellenv` either way. Add both to `main`.

- [ ] **Step 4: Run, expect all green**

Run: `bash tests/setup-macos/run.sh` → `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add setup/macos/install.sh tests/setup-macos/run.sh
git commit -m "feat(setup): install Command Line Tools and Homebrew, with the USTC mirror"
```

---

### Task 4: oh-my-zsh and powerlevel10k

**Files:**
- Modify: `setup/macos/install.sh`
- Modify: `tests/setup-macos/run.sh`
- Modify: `tests/setup-macos/http/` (add a truncated listing fixture for a second commit value used only by one test, e.g. `@deadbeef…`; the script reads `P10K_COMMIT` from env when `SETUP_P10K_COMMIT` is set, test-only override)

**Interfaces:**
- Consumes: `run`, `say_*`, curl/git stubs, `SETUP_MIRROR`.
- Produces: `step_omz`, `step_p10k`, `P10K_COMMIT` (overridable by `SETUP_P10K_COMMIT`), `P10K_CDN=https://cdn.jsdelivr.net/gh/romkatv/powerlevel10k`, `P10K_LIST=https://data.jsdelivr.com/v1/packages/gh/romkatv/powerlevel10k`, `ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"`.

- [ ] **Step 1: Write the tests**

```bash
fresh; install >/dev/null; t_out "omz default installer" 'curl .*raw\.githubusercontent\.com/ohmyzsh/ohmyzsh/master/tools/install\.sh' calls
t_true "omz unattended keeps zshrc" bash -c 'grep -q -- "--unattended --keep-zshrc" "$1"' _ "$SETUP_LOG"
fresh; SETUP_MIRROR=jsdelivr install >/dev/null; t_out "omz mirror installer" 'curl .*install\.ohmyz\.sh/' calls
t_no_out "omz mirror mode without failure stays on github" 'gitee\.com/mirrors/oh-my-zsh' calls
fresh; SETUP_MIRROR=jsdelivr STUB_GIT_FAIL='*github.com/ohmyzsh*' install >/dev/null
t_out "omz falls back to gitee" 'REMOTE=https://gitee\.com/mirrors/oh-my-zsh\.git' cat "$SETUP_LOG"
fresh; STUB_GIT_FAIL='*github.com/ohmyzsh*' t_out "omz default mode does not fall back" '\[ 4/10\] oh-my-zsh\n\s+installer\s+FAIL' install
fresh; install >/dev/null; t_out "p10k default clones github" 'git clone --depth=1 https://github\.com/romkatv/powerlevel10k\.git' calls
fresh; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "p10k mirror lists the pinned commit" "data\.jsdelivr\.com/v1/packages/gh/romkatv/powerlevel10k@$P10K_COMMIT\?structure=flat" calls
t_true "p10k mirror fetched every listed file" test -f "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/internal/p10k.zsh"
t_no_out "p10k mirror never touches github" 'github\.com/romkatv' calls
t_no_out "p10k mirror never asks for a branch" 'powerlevel10k@master' calls
t_no_out "package name is not taken for a file" 'powerlevel10k@[0-9a-f]+romkatv' calls
fresh; SETUP_MIRROR=jsdelivr SETUP_P10K_COMMIT=deadbeef install >/dev/null
t_true "bad listing leaves no p10k dir" test ! -e "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fresh; mkdir -p "$HOME/.oh-my-zsh/.git" "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"; t_out "omz and p10k present are skipped" 'oh-my-zsh\n\s+already installed\s+skip\n.*powerlevel10k\n\s+already installed\s+skip' install
```

`P10K_COMMIT` in run.sh is the same literal as in the script; `fresh` unsets `SETUP_P10K_COMMIT` and `STUB_GIT_FAIL`.

- [ ] **Step 2: Run, expect the new tests to fail**

- [ ] **Step 3: Implement `step_omz` and `step_p10k`**

`step_omz`: skip when `$HOME/.oh-my-zsh/.git` exists. Otherwise `omz_install <installer-url> [remote]`: `run env ${remote:+REMOTE=$remote} GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=30 sh -c "$(curl -fsSL "$url")" "" --unattended --keep-zshrc` (the `env` line is what the log test greps). Default mode: GitHub URL, no remote, `FAIL` on error. Mirror mode: `install.ohmyz.sh`, on error `say_notice "github.com timed out or failed, trying the gitee mirror"` and retry with `remote=https://gitee.com/mirrors/oh-my-zsh.git`, `FAIL` if that also fails. `step_p10k`: `dest=$ZSH_CUSTOM_DIR/themes/powerlevel10k`; skip when it exists. Default: `run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest"`. Mirror: `tmp=$(mktemp -d)`; `curl -fsSL "$P10K_LIST@$P10K_COMMIT?structure=flat"`; drop everything up to and including `"files":[` (`sed 's/.*"files": *\[//'`) so the top-level package `"name"` is gone, split entries with `tr '}' '\n'`, extract with `sed -n 's/.*"name": *"\([^"]*\)".*/\1/p'`; `FAIL` when the list is empty; for each name `curl -fsSL --create-dirs -o "$tmp$name" "$P10K_CDN@$P10K_COMMIT$name"`, `FAIL` on any error (tmp removed by an EXIT trap); `chmod +x "$tmp"/gitstatus/{build,install,mbuild}` when present; `mv "$tmp" "$dest"`; item text `N files from jsDelivr @<7-char sha>`.

- [ ] **Step 4: Run, expect all green**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(setup): install oh-my-zsh with gitee fallback and powerlevel10k from jsDelivr in mirror mode"
```

---

### Task 5: brew packages: zsh plugins, fonts, apps, CLIs, Grok

**Files:**
- Modify: `setup/macos/install.sh`
- Modify: `tests/setup-macos/run.sh`

**Interfaces:**
- Consumes: `run`, `say_*`, `BREW_PREFIX`, `APPS_DIR`, `LEFT_IN_PLACE`, brew/curl/pgrep stubs.
- Produces: `brew_formula <name>` and `brew_cask <name> [App Name.app]`, each printing one `say_item` line and setting `RESULT` to `done|skip|adopt|FAIL`; `step_zsh_plugins`, `step_fonts`, `step_apps`, `step_clis`.
  - `brew_formula`: skip when `brew list --formula <name>` succeeds; else `run brew install -q <name>`.
  - `brew_cask`: skip when `brew list --cask <name>` succeeds. When an app name is given and `$APPS_DIR/<app>` exists → `run brew install -q --cask --adopt <name>`, status `adopt`, and append `"<app>  $APPS_DIR/<app>  now managed by brew"` to `LEFT_IN_PLACE`. Otherwise `run brew install -q --cask <name>`. On any failure retry once with `--force`; if the retry succeeds status is `done` (or `adopt`) with `say_notice "<name>: an earlier install was in the way, overwrote it"`; else `FAIL`.
  - `step_clis` additionally: when `brew list --cask claude-code` succeeds, `say_notice "replacing cask claude-code with claude-code@latest"` and `run brew uninstall -q --cask claude-code` first; Grok: skip when `$HOME/.grok/bin/grok` is executable, else `run /bin/bash -c "$(curl -fsSL https://x.ai/cli/install.sh)"`; when `command -v codex` resolves outside `$BREW_PREFIX` before the install, append `"codex  <path>  brew version is first on PATH"` to `LEFT_IN_PLACE` (same for `claude`).
  - `step_zsh_plugins`: formulas `zsh-syntax-highlighting zsh-autosuggestions zsh-completions grep`, then `chmod go-w "$BREW_PREFIX/share"` and `chmod -R go-w "$BREW_PREFIX/share/zsh"` when those dirs exist (silent).
  - `step_fonts`: skip when `$HOME/Library/Fonts/MesloLGS NF Regular.ttf` exists; else `brew_cask font-meslo-for-powerlevel10k`.
  - `step_apps`: `brew_cask iterm2 iTerm.app`, `brew_cask visual-studio-code "Visual Studio Code.app"`.
  - `step_clis`: `brew_cask miniconda`, the claude-code replacement then `brew_cask claude-code@latest`, `brew_cask codex`, Grok.

- [ ] **Step 1: Write the tests**

```bash
fresh; install >/dev/null
t_out "four zsh formulas installed" 'brew install -q zsh-syntax-highlighting\n.*zsh-autosuggestions\n.*zsh-completions\n.*grep' calls
t_true "share dirs lose group write" bash -c '[ "$(stat -f %Sp "$1/share" | cut -c6)" = "-" ]' _ "$SETUP_BREW_PREFIX"
t_out "font cask installed" 'brew install -q --cask font-meslo-for-powerlevel10k' calls
fresh; mkdir -p "$HOME/Library/Fonts"; touch "$HOME/Library/Fonts/MesloLGS NF Regular.ttf"; t_out "font present is skipped" 'MesloLGS NF already in ~/Library/Fonts\s+skip' install
fresh; mkdir -p "$SETUP_APPS_DIR/iTerm.app"; install > "$tmp/out"
t_out "dmg-installed app is adopted" 'brew install -q --cask --adopt iterm2' calls
t_out "adopt shows in output" 'iTerm2.*\s+adopt' cat "$tmp/out"
fresh; mkdir -p "$SETUP_APPS_DIR/iTerm.app"; STUB_BREW_FAIL=iterm2 STUB_BREW_FORCE_OK=iterm2 install >/dev/null
t_out "refused adopt retries with force" 'brew install -q --cask --adopt iterm2\n(.*\n)*brew install -q --cask --adopt --force iterm2' calls
fresh; printf 'cask:claude-code\n' > "$STUB_BREW_STATE"; install >/dev/null
t_out "conflicting cask replaced" 'brew uninstall -q --cask claude-code\n(.*\n)*brew install -q --cask claude-code@latest' calls
fresh; mkdir -p "$tmp/npm"; touch "$tmp/npm/codex"; chmod +x "$tmp/npm/codex"; EXTRA_PATH="$tmp/npm" install > "$tmp/out"
t_out "npm codex listed as left in place" "codex\s+$tmp/npm/codex\s+brew version is first on PATH" cat "$tmp/out"
fresh; STUB_BREW_FAIL=codex t_exit "failed cask stops the run" 1 install
fresh; STUB_BREW_FAIL=codex t_out "failure shows log tail and path" 'codex\s+FAIL\n\n.*brew install.*exited 1\.\n(\s+│.*\n){1,3}\s+Full log: .*setup\.log\n\s+Fix the problem and run the same command again' install
fresh; STUB_BREW_FAIL=codex install >/dev/null 2>&1; : > "$STUB_LOG"; install >/dev/null
t_out "failed cask retried on rerun" 'brew install -q --cask codex' calls
t_no_out "finished steps not redone on rerun" 'brew install -q --cask miniconda' calls
fresh; install >/dev/null; t_out "grok installer fetched" 'curl .*x\.ai/cli/install\.sh' calls
```

- [ ] **Step 2: Run, expect the new tests to fail**

- [ ] **Step 3: Implement the helpers and four steps, add them to `main`**

- [ ] **Step 4: Run, expect all green**

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(setup): brew zsh plugins, fonts, iTerm2, VS Code, miniconda, Claude Code, Codex and Grok, adopting earlier installs"
```

---

### Task 6: Dotfiles, iTerm2 profile, summary, idempotency

**Files:**
- Modify: `setup/macos/install.sh`
- Modify: `tests/setup-macos/run.sh`

**Interfaces:**
- Consumes: `fetch_template`, `say_*`, counters, `LEFT_IN_PLACE`, defaults/pgrep stubs, Task 1 templates.
- Produces:
  - `prepare_dotfiles`, called by `main` right after `step_preflight` (its lines print under the Preflight banner): fetches `zshrc`, `p10k.zsh`, `iterm2-profile.json` into `WORK=$(mktemp -d)` (`FAIL` here means nothing has been installed yet); for `~/.zshrc` and `~/.p10k.zsh` that exist and differ from the template (`cmp -s`), copies them to `<file>.backup-<YYYYMMDD-HHMMSS>` and records the path in `BACKUPS`, item line `backup ~/.zshrc → <path>` with status `ok`. Backups happen here, before any installer can append to `.zshrc`.
  - `place_file <src> <dest>`: `skip` when `<dest>` equals `<src>`, else copy and `done`. Never backs up; `prepare_dotfiles` already did.
  - `ensure_zprofile`: appends `eval "$(/opt/homebrew/bin/brew shellenv)"` unless a line matching `brew shellenv` exists; in mirror mode appends a block delimited by `# >>> setup/macos: homebrew mirror >>>` / `# <<< setup/macos: homebrew mirror <<<` holding `export HOMEBREW_BREW_GIT_REMOTE=…`, `HOMEBREW_API_DOMAIN=…`, `HOMEBREW_BOTTLE_DOMAIN=…` with the effective values after `brew_env` (so a value the person preset is the one written), unless the start marker exists.
  - `install_iterm_profile`: `place_file "$WORK/iterm2-profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/workflow.json"`; reads the Guid with `sed -n 's/.*"Guid": *"\([^"]*\)".*/\1/p'`; when `pgrep -x iTerm2` succeeds → `say_notice "iTerm2 is running, not changing its default profile; pick \"workflow\" in iTerm2 > Settings > Profiles"`, else `run defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$guid"`. This works before iTerm2's first launch: `ITAddressBookMgr` init reads `Default Bookmark Guid`, loads dynamic profiles, and calls `setDefaultByGuid` when that guid exists only among them (`sources/Settings/Profiles/ITAddressBookMgr.m`).
  - `step_dotfiles`: `place_file` for `.zshrc` and `.p10k.zsh` from `$WORK`, then `ensure_zprofile`, then `install_iterm_profile`.
- `summary`: `==> Done in MmSSs.` then `N installed, M already in place.` (installed = `N_DONE + N_ADOPT`, in place = `N_SKIP`); `Backups:` list when `BACKUPS` is non-empty; `Earlier installs left on this Mac:` list when `LEFT_IN_PLACE` is non-empty; `Next:` four numbered lines from the spec; a fifth line `Your login shell is <shell>; run: chsh -s /bin/zsh` when `${SHELL##*/}` ≠ `zsh`.

- [ ] **Step 1: Write the tests**

```bash
fresh; install > "$tmp/out"
t_true "zshrc equals template" cmp -s "$setup/zshrc" "$HOME/.zshrc"
t_true "p10k equals template" cmp -s "$setup/p10k.zsh" "$HOME/.p10k.zsh"
t_true "iterm profile installed" cmp -s "$setup/iterm2-profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/workflow.json"
t_out "default profile set" 'defaults write com.googlecode.iterm2 Default Bookmark Guid -string 9B8C7E2A-4F31-4C5D-A6E0-2D7F5B3C9A11' calls
t_true "zprofile has one shellenv line" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
t_no_out "default mode writes no mirror block" 'homebrew mirror' cat "$HOME/.zprofile"
t_out "summary counts" '==> Done in \d+m\d\ds\. \d+ installed, \d+ already in place\.' cat "$tmp/out"
t_out "next steps listed" 'Next:\n\s+1\. Quit Terminal and open iTerm2\.\n\s+2\. claude\n\s+3\. codex login\n\s+4\. grok' cat "$tmp/out"
: > "$STUB_LOG"; install > "$tmp/out2"
t_true "second run makes no backup" bash -c '! ls "$1"/.zshrc.backup-* "$1"/.p10k.zsh.backup-* 2>/dev/null' _ "$HOME"
t_no_out "second run installs nothing" 'brew install|git clone|softwareupdate -i' calls
t_true "second run keeps one shellenv line" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
t_out "second run says everything is in place" '0 installed, \d+ already in place' cat "$tmp/out2"
fresh; printf 'export OLD=1\n' > "$HOME/.zshrc"; install > "$tmp/out"
t_true "different zshrc is backed up" bash -c 'ls "$1"/.zshrc.backup-* >/dev/null 2>&1' _ "$HOME"
t_out "backup path appears in summary" 'Backups:\n\s+.*/\.zshrc\.backup-\d{8}-\d{6}' cat "$tmp/out"
t_true "old content is in the backup" bash -c 'grep -q "export OLD=1" "$1"/.zshrc.backup-*' _ "$HOME"
t_true "backup taken before installers ran" bash -c '! grep -q "grok installer" "$1"/.zshrc.backup-*' _ "$HOME"
t_true "only one backup per file" bash -c '[ "$(ls "$1"/.zshrc.backup-* | wc -l)" -eq 1 ]' _ "$HOME"
fresh; install >/dev/null; t_true "no zshrc before means no backup" bash -c '! ls "$1"/.zshrc.backup-* 2>/dev/null' _ "$HOME"
fresh; STUB_BREW_FAIL=codex install >/dev/null 2>&1; t_true "failed run has not touched zshrc yet" test ! -e "$HOME/.zshrc"
fresh; printf 'export STRAY=1\n' > "$tmp/zshrc"; install_piped >/dev/null
t_true "stray zshrc in cwd is not used" cmp -s "$setup/zshrc" "$HOME/.zshrc"
t_out "piped run fetches templates from github" 'curl .*raw\.githubusercontent\.com/etherfunlab/workflow/main/setup/macos/zshrc' calls
fresh; SETUP_MIRROR=jsdelivr install_piped >/dev/null
t_out "mirror run fetches templates from jsDelivr" 'curl .*cdn\.jsdelivr\.net/gh/etherfunlab/workflow@main/setup/macos/zshrc' calls
t_no_out "mirror run never asks raw.githubusercontent.com for templates" 'raw\.githubusercontent\.com/etherfunlab' calls
fresh; cp "$setup/zshrc" "$HOME/.zshrc"; install >/dev/null
t_true "identical zshrc is not backed up" bash -c '! ls "$1"/.zshrc.backup-* 2>/dev/null' _ "$HOME"
fresh; printf "eval \"\$(/opt/homebrew/bin/brew shellenv)\"\n" > "$HOME/.zprofile"; install >/dev/null
t_true "shellenv line already present with different quoting" bash -c '[ "$(grep -c "brew shellenv" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; SETUP_MIRROR=jsdelivr install >/dev/null
t_out "mirror block written once" '# >>> setup/macos: homebrew mirror >>>\nexport HOMEBREW_BREW_GIT_REMOTE=.*\nexport HOMEBREW_API_DOMAIN=.*\nexport HOMEBREW_BOTTLE_DOMAIN=.*\n# <<< setup/macos: homebrew mirror <<<' cat "$HOME/.zprofile"
SETUP_MIRROR=jsdelivr install >/dev/null; t_true "mirror block not duplicated" bash -c '[ "$(grep -c "homebrew mirror >>>" "$1")" = 1 ]' _ "$HOME/.zprofile"
fresh; STUB_ITERM_RUNNING=1 install > "$tmp/out"
t_no_out "running iTerm2 keeps its default" 'defaults write' calls
t_out "running iTerm2 is explained" 'iTerm2 is running, not changing its default profile' cat "$tmp/out"
fresh; SHELL=/bin/bash t_out "non-zsh login shell gets a hint" 'login shell is bash; run: chsh -s /bin/zsh' install
fresh; t_out "piped output has no color" '==> \[10/10\] Dotfiles' install
```

- [ ] **Step 2: Run, expect the new tests to fail**

- [ ] **Step 3: Implement `prepare_dotfiles`, `place_file`, `ensure_zprofile`, `install_iterm_profile`, `step_dotfiles`, `summary`; complete `main`**

`main` records the start time before preflight for the summary. Note: "failed run has not touched zshrc yet" holds because the grok fixture runs after codex; the real grok installer may still edit `.zshrc` on a run that fails later, which the next run's `place_file` overwrites.

- [ ] **Step 4: Run the whole suite and the syntax checks**

Run: `bash tests/setup-macos/run.sh && bash -n setup/macos/install.sh && bash tests/run-all.sh`
Expected: every suite reports `0 failed`; `lint_modules: ok`.

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(setup): write dotfiles with backups, install the iTerm2 profile, print the summary"
```

---

### Task 7: Docs and maintenance rules

**Files:**
- Modify: `README.md` (after `## Supplementary skills`, before `## Upstream`), `README.zh.md` (after `## 补充 skills`), `README.de.md` (after `## Ergänzende Skills`), `README.ja.md` (after `## 補足 skill`)
- Modify: `AGENTS.md`
- Modify: `README.md` Chinese header block "怎么用" / "How to use": no change (the setup script is not part of ADOPT)

**Interfaces:**
- Consumes: the start lines and `SETUP_MIRROR` name from Task 2, file list from Tasks 1–6.

- [ ] **Step 1: Write the README section in English (`README.md`)**

Heading `## Environment setup`. Content, in this order: one paragraph (what the script installs: the list from the spec's goals, in one sentence; Apple Silicon only; what it writes into `$HOME` and that existing `.zshrc`/`.p10k.zsh` are backed up); a code block with the default start line; one sentence introducing weak-network mode and a code block with the `SETUP_MIRROR=jsdelivr` line; one sentence saying what the mirror mode changes (repo files via jsDelivr, Homebrew via the USTC mirror, oh-my-zsh falls back to the gitee mirror, powerlevel10k pinned to a commit) and that app and CLI downloads still come from their vendors; one sentence that it stops at the first failure and the same line reruns safely.

- [ ] **Step 2: Write the same section in `README.zh.md` (`## 环境配置脚本`), `README.de.md` (`## Umgebung einrichten`), `README.ja.md` (`## 環境構築 script`)**

Same order and content; same `##` position relative to neighbours. Japanese: kanji words over katakana, technical terms in English (`script`, `Homebrew`, `mirror`).

- [ ] **Step 3: Add Homebrew, oh-my-zsh and powerlevel10k to the Upstream list in all four READMEs**

One line each, same form as the existing entries: `- [Homebrew](https://brew.sh): the setup script`, `- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh): the setup script`, `- [powerlevel10k](https://github.com/romkatv/powerlevel10k): the setup script` (translated role text in zh/de/ja).

- [ ] **Step 4: Add two bullets to `AGENTS.md` under "If you are maintaining this repo"**

- Amend the language bullet so `setup/` is listed with `agent/`, `templates/` and `tests/`.
- New bullet: "After a change under `setup/` lands on `main`, purge the jsDelivr cache for each changed file: `curl -fsS https://purge.jsdelivr.net/gh/etherfunlab/workflow@main/<path>`. jsDelivr caches branch references for 12 hours, and mirror-mode installs read `install.sh` and the templates from it."
- New bullet: "`P10K_COMMIT` in `setup/macos/install.sh` is updated by hand; bump it after checking that powerlevel10k's master still installs from jsDelivr with `SETUP_MIRROR=jsdelivr`."

- [ ] **Step 5: Check heading parity and run everything**

Run: `for f in README.md README.zh.md README.de.md README.ja.md; do printf '%s ' "$f"; grep -c '^## ' "$f"; done` before Step 1 and again now; each count is exactly one higher.
Run: `bash tests/run-all.sh` → all `0 failed`, `lint_modules: ok`.

- [ ] **Step 6: Commit**

```bash
git add README.md README.zh.md README.de.md README.ja.md AGENTS.md
git commit -m "docs: environment setup section in the four READMEs, jsDelivr purge rule"
```

- [ ] **Step 7: Stop and ask the maintainer before pushing**

Pushing and opening the PR are the maintainer's call. When they say go: confirm `gh pr list --state open` is empty, `git push -u origin feat/macos-setup`, `gh pr create --title "feat(setup): macOS environment setup script"` with a body covering what it installs, the two start lines, the mirror mode, and how it was tested (stub suite; not yet run on a clean Mac), ending with the attribution line from the session reminder.

---

## Verification on a real Mac (maintainer's step, not part of the tasks)

On a clean macOS user account or VM, in Terminal.app, run the default start line; then open iTerm2 and confirm: prompt renders with powerlevel10k glyphs in the `workflow` profile, `conda --version` works, `claude --version`, `codex --version`, `code --version`, `grok --version` resolve under `/opt/homebrew/bin` or `~/.grok/bin`. Run the same line again and confirm the summary says `0 installed`. Repeat once with `SETUP_MIRROR=jsdelivr` on a fresh account.
