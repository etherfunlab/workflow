# dev-root

From the principle: One source of truth. Cross-repo posture goes in the upper-level file; a rule for one repository stays in that repository.

## What it is

A CLAUDE.md template for the directory one level above your repositories: the production data channel, windows and eras on reported numbers, public-repo discipline, PR cadence, per-call APIs, human-judged look-and-feel, investigate-first, commit hygiene. Claude Code loads a parent directory's CLAUDE.md into every session in the repositories underneath, so one copy of these rules covers them all.

## Why

Copy these rules into each repository and one copy eventually falls behind. One copy in the parent directory is One source of truth applied to rule files. That directory is usually not a git repository, so a hook mirrors the file into one for history, and the mirror is never edited by hand.

## What gets installed

- `CLAUDE.md`, written to the directory above the target repository (not into it), with blanks written `TODO:` for you to fill.
- **Claude Code only**: other agents do not read parent directories. With another agent, merge the entries you want into each repository's AGENTS.md.

## Dependencies

None. For mirror history, adapt `mirror-rules-backup.example.sh` from the rules-files module.
