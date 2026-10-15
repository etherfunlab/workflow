# ADOPT — wiring this workflow into a project

You are an AI agent. The user handed you this repository and asked you to wire it into their project, the *target*. Follow the steps in order. Do not skip step 3.

## Ground rules

- The user decides. Ask before writing anything. Never overwrite or delete the user's existing rules, hooks or settings.
- Ask one question at a time.
- Write rule text in the language the user picks, in the voice of their existing rule files. Keep each rule's meaning; add no rules of your own.
- `README*.md` files here are for people. Never copy them, the principles, or the "Active noise reduction" lead into the target's rule files.
- Items marked **[CC]** need Claude Code. Other agents skip them and say so in the report.

## Principles

Modules cite principles by number in `module.json`: 2 Constraints first, 3 Code is king, 4 Repo management, 5 Weak? Practice., 6 One source of truth, 7 CLIs call CLIs, 8 Watch the interfaces, 10 Issues between repos. (1 Active noise reduction and 9 Talk first, then run are for people and never become rules.) `extras/` come from no principle.

## 1. Read before you ask

1. Identify yourself: Claude Code, or another agent.
2. Upstream is the copy of this repository you were given (a local path or GitHub). Record `git -C <upstream> rev-parse HEAD` as the commit. Record `upstream` as `git -C <upstream> remote get-url origin` when that is an https URL, else the path.
3. Classify the target:
   - it has `.workflow.lock` → **update**, go to section 7;
   - it has no CLAUDE.md, AGENTS.md or `.claude/` → **new project**;
   - otherwise → **existing project**. Read in full: CLAUDE.md, AGENTS.md, every file they import with `@`, every `.claude/rules/*.md`, `.claude/settings.json`, `.claude/settings.local.json`, and the git hook setup (`git config core.hooksPath`, `.git/hooks/pre-push`, `.githooks/`).
4. Read every `modules/*/module.json` and `extras/*/module.json` here.

## 2. Ask

1. **Modules.** Show a table: name, one line on what it does, the principles it comes from, **[CC]** when it needs Claude Code. When a chosen module has `depends_on`, add those modules and say so. List `extras/` separately as supplements.
2. **Language** of rule text: Chinese or English.
3. **Skill location:** project (`.claude/skills/`, committed and shared; Codex: `.agents/skills/`) or user (`~/.claude/skills/`; Codex: `~/.agents/skills/`).
4. **Optional hooks [CC]:** each entry in the chosen modules' `hooks` with `"optional": true`.

Then ask for each `placeholders` key of the chosen modules, offering its `default`. Check each `requires` command with `command -v`; report missing ones with an install hint and do not install them yourself.

## 3. Show the change list, then wait

List every file you will create or change, one line each saying what goes in, merges into existing files included. For each module rule that conflicts with an existing rule, quote both and ask which to keep. For each module rule the target already has in substance (anywhere, including `@`-imported files), say you will skip it. Write nothing until the user says yes.

## 4. Apply

**New project:** copy `template/` into the target first, skipping files that exist, then continue.

**Rules** (`rules` in `module.json`):

- A rule file without `paths:` frontmatter is merged into the target's main rule file under a `##` heading named after the module (`## Engineering`). The main rule file is AGENTS.md if it exists; else CLAUDE.md if it exists; else create AGENTS.md (and for Claude Code a CLAUDE.md containing `@AGENTS.md`).
- A rule file with `paths:` frontmatter: **[CC]** write it to `.claude/rules/<module>.md`, keeping the frontmatter. Other agents: merge it into AGENTS.md under `## When editing <paths>`.
- A rule file with `## Claude Code` and `## Other agents` sections: keep only the section that matches you.
- Skip rules the target already has in substance, and conflicting rules the user chose not to take.
- Replace every `{{PLACEHOLDER}}` with the user's answer. When an answer is empty, delete the line that held the placeholder.

**Skills** (`skills`): copy each `agent/skills/<name>/` directory to the chosen location, replace placeholders, and keep scripts executable (`chmod +x`).

**Third-party skills** (`upstream_skills`): when one is not installed, show the user its URL and the install command from its README; install it only with a yes.

**Copies** (`copies`): copy `from` to `to` when `to` does not exist.

**Git hooks** (`git_hooks`): copy them to `.githooks/` and `chmod +x`. If the target has no pre-push hook and `core.hooksPath` is unset, run `git config core.hooksPath .githooks`. If a pre-push hook exists, keep it and add one line calling `.githooks/<module>-pre-push.sh`; do not copy `pre-push`.

**Hooks [CC]** (`hooks`, only those the user accepted): copy `file` to `install_to`, then add an entry to `.claude/settings.json` (or `~/.claude/settings.json` when `install_to` starts with `~`), appending to the existing arrays and never replacing entries:

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
    "engineering": { "files": ["AGENTS.md#Engineering"] },
    "publish": { "files": [".claude/skills/doc-publish/", ".claude/skills/doc-fact-check/"] }
  }
}
```

`files` lists everything you created or changed for each module. A section merged into a file is written `path#Heading`. Insert no markers into rule files; the lock is the only record of where things came from.

## 6. Report

- Created and changed files, per module.
- Skipped items and why: already present, user declined, conflict kept, needs Claude Code.
- Missing commands and how to install them.
- How to update later: hand this repository to the agent again.

## 7. Update

1. Read `.workflow.lock`. For each installed module run `git -C <upstream> diff <commit>..HEAD -- modules/<name> extras/<name> template`.
2. Summarize the changes per module in plain words: rule added, rule removed, wording changed, placeholder added, file renamed.
3. Ask whether to apply each module's changes. A rule removed upstream is removed from the target only with a yes.
4. Apply as in section 4, merging by meaning into the sections the lock lists and keeping the user's own edits to those sections.
5. Update `commit` and `adopted_at`, and `files` when they changed.
6. Report as in section 6.
