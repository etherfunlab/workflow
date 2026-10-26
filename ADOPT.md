# ADOPT — wiring this workflow into a project

You are an AI agent. The user handed you this repository and asked you to wire it into their project, the *target*. Follow the steps in order. Do not skip step 3.

## Ground rules

- The user decides. Ask before writing anything. Never overwrite or delete the user's existing rules, hooks or settings.
- Ask one question at a time.
- Write rule text in the language the user picks, in the voice of their existing rule files. Keep each rule's meaning; add no rules of your own.
- `README*.md` files here are for people. Never copy them, the principles, or the "Active noise reduction" lead into the target's rule files.
- Items marked **[CC]** need Claude Code. Other agents skip them and say so in the report.

## Principles

Modules cite principles by number in `module.json`: 2 Constraints first, 3 Code is king, 4 Repo management, 5 Weak? Practice., 6 One source of truth, 7 CLIs call CLIs, 8 Watch the interfaces, 10 Issues between repos. (1 Active noise reduction and 9 Talk first, then run are for people and never become rules.) Supplementary skills under `skills/` come from no principle.

## 1. Read before you ask

1. Identify yourself: Claude Code, or another agent.
2. Upstream is the copy of this repository you were given (a local path or GitHub). Work from its committed content at HEAD; if its working tree has uncommitted changes, say so in the report and ignore them. Record `git -C <upstream> rev-parse HEAD` as the commit. Record `upstream` as `git -C <upstream> remote get-url origin` when that is an https URL, else the path.
3. Classify the target:
   - it has `.workflow.lock` → **update**, go to section 7;
   - it has no CLAUDE.md, AGENTS.md or `.claude/` → **new project**;
   - otherwise → **existing project**. Read in full: CLAUDE.md, AGENTS.md, every file they import with `@`, every `.claude/rules/*.md`, `.claude/settings.json`, `.claude/settings.local.json`, and the git hook setup (`git config core.hooksPath`, `.git/hooks/pre-push`, `.githooks/`).
4. Read the rule files your agent loads from outside the target, for a new project too: the user-level file (Claude Code: `~/.claude/CLAUDE.md`; Codex: `~/.codex/AGENTS.md`) and, for Claude Code, every CLAUDE.md in the target's parent directories, with the files they import. These files do not travel with the repository; section 3 decides what happens to rules found there.
5. Read every `modules/*/module.json` and `skills/*/module.json` here, and the "What it is" section of each `templates/*/README.en.md`.

## 2. Ask

1. **Modules.** Show a table: name, one line on what it does, the principles it comes from, **[CC]** when it needs Claude Code. When a chosen module has `depends_on`, add those modules and say so. List `skills/` separately as supplementary skills.
2. **Templates.** List each `templates/*/` other than `base`, one line each, and ask which to add. A new project always gets `base`; an existing project gets only the templates chosen here.
3. **Language** of rule text and template files: Chinese or English.
4. **Skill location**, only when a chosen module installs skills: project (`.claude/skills/`, committed and shared; Codex: `.agents/skills/`) or user (`~/.claude/skills/`; Codex: `~/.agents/skills/`).
5. **Optional hooks [CC]:** each entry in the chosen modules' `hooks` with `"optional": true`.

Then ask for each `placeholders` key of the chosen modules, offering its `default`; `<skills-dir>` in a default means the skill location chosen in question 4. When an answer names a path that does not exist in the target, say so in the change list. Check each `requires` command with `command -v`; report missing ones with an install hint and do not install them yourself.

## 3. Show the change list, then wait

List every file you will create or change, one line each saying what goes in, merges into existing files included. For each module rule that conflicts with an existing rule, quote both and ask which to keep. For each module rule the target already has in substance (anywhere in the target, including `@`-imported files), say you will skip it. For each module rule found only in a file outside the target (section 1, step 4), quote that file's rule and ask whether to skip the module rule or install it anyway: a teammate, another machine or another agent does not load that file. Write nothing until the user says yes.

## 4. Apply

**Templates** go first, `base` (new project only) before the others. Install each file of `templates/<name>/` except `README.*.md` at the same path in the target, written in the chosen language:

- The AGENTS.md of a template other than `base` is never copied as a file. It merges into the target's main rule file (defined under Rules below): its rows join the table under the same `##` heading, numbered after the rows already there, and when that file has no such table, add the heading and the table. Its other `##` sections are appended; when that file already has a section with the same heading, merge into it as for module rules: skip what it already says in substance, and ask on a conflict.
- Every other file is copied when the target lacks it. A file the target already has is skipped and named in the report.
- `TODO:` marks a blank the team fills later. Keep each one as it is.

**Rules** (`rules` in `module.json`):

- A rule file without `paths:` frontmatter is merged into the target's main rule file under a `##` heading named after the module (`## Engineering`): the rule file's own `#` title is replaced by that heading and its `##` sections become `###`. The main rule file is AGENTS.md if it exists; else CLAUDE.md if it exists; else create AGENTS.md (and for Claude Code a CLAUDE.md containing `@AGENTS.md`).
- When the main rule file is an index (a "Read in this order" or directory table, as in `templates/base/AGENTS.md`), add a row for each rule file or directory you create.
- **[CC]** Claude Code loads CLAUDE.md, not AGENTS.md. Whenever rules go into AGENTS.md and CLAUDE.md does not already import it, add the line `@AGENTS.md` to CLAUDE.md (creating CLAUDE.md if needed) and include that in the change list.
- A rule file with `paths:` frontmatter: **[CC]** write it to `.claude/rules/<module>.md`, keeping the frontmatter. Other agents: merge it into AGENTS.md under `## When editing <paths>`.
- A rule file with `## Claude Code` and `## Other agents` sections: keep only the content of the section that matches you, without that section's heading.
- Skip rules the target already has in substance, rules the user chose to leave to a file outside the target, and conflicting rules the user chose not to take. The unit is one bullet or one numbered item; when you skip one, name in the report any part of it that did not conflict.
- Replace every `{{PLACEHOLDER}}` with the user's answer. When an answer is empty and the placeholder is all its line or list item holds, delete that line; when it sits inside a longer line, replace it with nothing.

**Skills** (`skills`): copy each `agent/skills/<name>/` directory to the chosen location, replace placeholders, and keep scripts executable (`chmod +x`). When a skill with the same name already exists there and differs, show the difference and ask whether to replace it, keep the existing one, or skip; never overwrite it silently.

**Third-party skills** (`upstream_skills`): when one is not installed, show the user its URL and the install command from its README; install it only with a yes.

**Copies** (`copies`): copy `from` to `to` when `to` does not exist.

**Git hooks** (`git_hooks`): copy the module's scripts except `pre-push` to `.githooks/` and `chmod +x` (the cases below decide whether `pre-push` is copied); when a file with the same name already exists there and differs, ask before replacing it. The active hooks directory is the value of `git config core.hooksPath`, else `.git/hooks`.

- No pre-push hook there and `core.hooksPath` unset: run `git config core.hooksPath .githooks` and keep the copied `pre-push`.
- No pre-push hook there and `core.hooksPath` set to another directory: create a pre-push hook in that directory that runs the call line below; leave `core.hooksPath` as it is.
- A pre-push hook exists there: keep it and insert the call line right after its shebang, before any `exit` or `exec`, so it always runs; do not copy `pre-push`.

The call line is `"$(git rev-parse --show-toplevel)/.githooks/<module>-pre-push.sh" || exit 1`.

**Hooks [CC]** (`hooks`, only those the user accepted): copy `file` to `install_to`, then add an entry to `.claude/settings.json` (or `~/.claude/settings.json` when `install_to` starts with `~`), appending to the existing arrays and never replacing entries. Skip an entry whose command is already registered for that event:

```json
{"hooks": {"<event>": [{"matcher": "<matcher>", "hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/<install_to>"}]}]}}
```

For a user-level hook, the command is the absolute path of `install_to`.

## 5. Write `.workflow.lock`

JSON at the target's root, committed with the target:

```json
{
  "upstream": "https://github.com/etherfunlab/workflow",
  "commit": "<40-char sha>",
  "adopted_at": "YYYY-MM-DD",
  "language": "zh",
  "agent": "claude-code",
  "skills_scope": "project",
  "modules": {
    "templates/base": { "files": ["AGENTS.md", "CLAUDE.md", "docs/superpowers/specs/"] },
    "templates/frontend": { "files": ["DESIGN.md", "LOCALE.md", "AGENTS.md#Frontend"] },
    "engineering": { "files": ["AGENTS.md#Engineering"], "skipped": ["KISS: kept the user's rule on early abstraction"] },
    "publish": { "files": [".claude/skills/doc-publish/", ".claude/skills/doc-fact-check/"] }
  }
}
```

`files` lists everything you created or changed for each module; files from `templates/<name>/` go under `"templates/<name>"`. A section merged into a file is written `path#Heading`. `skipped` (optional) names each rule you left out and why, so an update does not offer it again; a rule left to a file outside the target names that file. Write `skills_scope` only when a chosen module installs skills. A module's own `commit` (optional) overrides the top-level one; section 7 sets it when the user declines that module's upstream changes. Insert no markers into rule files; the lock is the only record of where things came from.

## 6. Report

- Created and changed files, per module.
- Skipped items and why: already present, left to a file outside the target (name it), user declined, conflict kept, needs Claude Code.
- The `TODO:` blanks in template files, counted per file.
- Missing commands and how to install them.
- When you set `core.hooksPath`: it lives in the local git config, so everyone who clones the target runs `git config core.hooksPath .githooks` once.
- How to update later: hand this repository to the agent again.

## 7. Update

1. Read `.workflow.lock`. For each installed module run `git -C <upstream> diff <commit>..HEAD -- modules/<name> skills/<name>`, and for each `templates/<name>` key the same command on that path, where `<commit>` is the module's own `commit` when it has one, else the top-level `commit`. Paths renamed upstream are diffed under both names, so removals show up too: `template` and `templates/base` for the lock key `template` (rename that key to `templates/base`), and `extras/<name>` and `skills/<name>` for a supplementary skill.
2. Summarize the changes per module in plain words: rule added, rule removed, wording changed, placeholder added, file renamed.
3. Ask whether to apply each module's changes. A rule removed upstream is removed from the target only with a yes. A rule listed in `skipped` is not offered again unless it changed upstream.
4. Apply as in section 4, merging by meaning into the sections the lock lists and keeping the user's own edits to those sections, filled `TODO:` blanks included.
5. Set the top-level `commit` to upstream HEAD and update `adopted_at`, and `files` when they changed. For each module whose changes the user declined, set its own `commit` to the commit it was last updated from, so the next update offers those changes again; remove a module's own `commit` once its changes are applied.
6. Report as in section 6.
