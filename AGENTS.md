# AGENTS.md — etherfunlab/workflow

## If a user handed you this repo

Follow [ADOPT.md](ADOPT.md) to wire it into their project. Do not copy this file into their project.

## If you are maintaining this repo

- Every module under `modules/` comes from one or more principles in README.md. `module.json` lists them by number (see ADOPT.md § Principles) and both READMEs name them in their first paragraph. Skills of our own that come from no principle live under `skills/` with `"principles": []`.
- `README.zh.md` and `README.en.md` change together and keep the same `##` sections.
- `ADOPT.md`, this file, `module.json`, and everything under `agent/`, `template/` and `tests/` are English, except trigger phrases and quoted example words.
- No product names, private repository names, internal URLs, local absolute paths or personal emails anywhere in this repo, commit messages included.
- Run `tests/run-all.sh` before committing.
- Commits use Conventional Commits, in English.
