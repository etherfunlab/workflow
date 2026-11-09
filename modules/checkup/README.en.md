# checkup

From the principle: Weak? Practice. It is a tool people use for active noise reduction: a person triggers it and a person decides.

## What it is

A periodic checkup of your rule files. The agent reads every layer of CLAUDE.md and AGENTS.md (directories above the repo root included), `.claude/rules/` and memory, compares them with the system prompt it currently sees, and lists what to delete, shorten or move. It produces a list; you approve each change.

## Why

A rule is written against the harness of the day it was written. Each Claude Code release can change the system prompt. A rule that filled a gap back then may, a few versions later, say the same thing as the system prompt, or push against it.

Two other kinds of decay happen without any upgrade. Facts go stale: the script, path or command a rule names is gone. And brakes hide behind classification: a rule such as "if you judge this to be a side task, stop and ask" fires only after the agent classifies the situation, and the moment the brake is needed is the moment the classification gets skipped.

A rule in the context raises the odds that it is followed, nothing more. Reread the rules against the current harness from time to time and delete what no longer holds.

## How to use it

Say "rules checkup" (or 体检一下), or say it after the upgrade reminder appears. A checkup has three scopes, written after the command, as in `/rules-checkup repo`; with none given it is `project`:

| Scope | What it checks | Whose rules these are |
|---|---|---|
| `global` | Only `~/.claude` | Yours, in every project you open |
| `project` | Every rule file this session loads, from `~/.claude` down to the working directory, plus memory | Yours, working here |
| `repo` | Only the files the repository commits, at any depth | Everyone's who clones the repo |

Recommended order: `global` first, then `project`, then `repo`. A checkup can move a rule down a layer, and the next pass then reads that layer in its final form. `repo` reads nothing outside the repo, so repeating a rule that lives outside it is no candidate, and a rule that depends on a path outside it counts as a stale fact.

The agent lists candidates in six kinds:

| Kind | Test |
|---|---|
| Redundant | The system prompt already says the same thing, in the same direction |
| Conflicting | The rule pushes against the system prompt or another rule |
| Stale fact | A path, command, file, flag or name in the rule no longer exists; each one is checked with a command, never from memory |
| Duplicate | The same rule lives in memory and a rule file, in two rule files, or twice in one file; a memory that records what the repo or its git history already holds counts too |
| Hidden brake | A stop-or-ask rule that fires only after the agent classifies the situation |
| Incident residue | Dates, PR or issue numbers, line numbers, measured figures, post-mortems or tombstones inside a rule |

Each candidate comes with its location, the rule text, the reason and a proposed change. Nothing changes until you approve the item; "all" approves everything. A checkup only deletes, shortens or moves rules; it never adds one. After applying changes in the `project` scope, the skill records the date as `last_checkup` in `~/.claude/workflow-checkup.json`.

## What gets installed

- Skill `rules-checkup`, in the skills directory you chose.
- Optional (Claude Code only): SessionStart hook `checkup-reminder.sh` in `~/.claude/hooks/`, registered in the user-level `~/.claude/settings.json`. When `claude --version` differs from the last recorded version, it reminds you once at session start and then stays quiet; it never runs the checkup itself. It says nothing while the last checkup (`last_checkup`) is less than 14 days old, and reminds once that time has passed; the environment variable `WORKFLOW_CHECKUP_MIN_DAYS` changes the number of days. It records the version at its last reminder as `last_version` in `~/.claude/workflow-checkup.json`.

## Dependencies

`jq`, `perl`.
