# AGENTS.md — etherfunlab/workflow

## If a user handed you this repo

Follow [ADOPT.md](ADOPT.md) to wire it into their project. Do not copy this file into their project.

## If you are maintaining this repo

- Every module under `modules/` comes from one or more principles in README.md. `module.json` lists them by number (see ADOPT.md § Principles) and both READMEs name them in their first paragraph. Skills of our own that come from no principle live under `skills/` with `"principles": []`.
- Each `templates/<name>/` other than `base` has a `README.zh.md` and `README.en.md` that name its principles in their first paragraph. Blanks in template files are written `TODO:`, never `{{PLACEHOLDER}}`; cross-references cite `FILE.md §N`, naming the file on every cross-file reference (a bare `§N` means the same file), and `tests/templates/` checks that each one resolves.
- Which language each file is written in, and what each translation is translated from: [LOCALE.md](LOCALE.md). Read it before writing or changing a README, and before adding a file.
- After a change under `setup/` lands on `main`, purge jsDelivr's cache for each changed file: `curl -fsS https://purge.jsdelivr.net/gh/etherfunlab/workflow@main/<path>`. jsDelivr caches branch references for 12 hours, and mirror-mode installs read `install.sh` and its templates from it.
- `P10K_COMMIT` in `setup/macos/install.sh` is bumped by hand, after checking that the new commit installs with `SETUP_MIRROR=jsdelivr`.
- No product names, private repository names, internal URLs, local absolute paths or personal emails anywhere in this repo, commit messages included.
- Run `tests/run-all.sh` before committing.
- Commits use Conventional Commits, in English.
