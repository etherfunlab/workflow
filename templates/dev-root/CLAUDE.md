# Rules for every repository below this directory

This file sits one directory above the repositories it governs (TODO: name the directory). Claude Code loads it for every repository underneath. Keep only cross-repo posture here; a rule for one repository lives in that repository. This directory is usually not a git repository: mirror this file into one with a hook for history (the rules-files module ships an example script), and never edit the mirror.

## Production data

- Every repository reaches production data through one channel only: TODO: the one blessed command.
- Repositories that analyze the product (TODO: list them, such as audit, reporting and accounting repositories) are read-only on production data. Repositories that build the product may query and modify it.
- Raw production rows never echo to the terminal and never go into a report. Write them to a local file, aggregate locally, publish aggregates only — and when the data can be traced to a person, publish with the owner's consent per occasion.

## Numbers in reports

- Every number names its sampling window. When a threshold or constant changed in production, cut the window at the change.
- One deploy is one era: a deploy often changes version and configuration together, so text or metrics from different eras are not comparable. Compare within an era, or present segments and name the confound. Era boundaries come from the release list, not from git branches.

## Public repositories

The public repositories here (TODO: list them) never mention private repository names, internal project names, production URLs or local paths — in issues, PRs and commit messages alike. Evidence from production is anonymized ("a production deployment").

## Pull requests

One open PR at a time: parallel PRs entangle, and the human pays for the conflicts. When opening a PR is refused, stop and ask instead of opening another.

## APIs billed per call

External APIs billed per call (image generation, TTS, paid inference) never iterate automatically: one round, then show the result together with your judgment and let the user decide whether and how to run again. Only transient errors (5xx, timeouts) of the same call may be retried, with a cap; a reworded prompt is a new round.

## Judgment that lives in human eyes

Look-and-feel, layout, art direction and copy tone are judged by people; scripts and metrics cannot. No self-scoring, no test assertions on these values. Produce the candidates in one batch (about three per theme), side by side, then stop: waiting for the human to pick is the correct end state, not unfinished work.

## Requirements: investigate first, then ask

The user's description is the requirement; reading it back for confirmation makes the user say it twice. For a bug report, go to the code, logs and data and locate the cause before changing anything. Ask only when the evidence truly supports two readings, ask that fork alone, and offer options whenever options can be listed.

## Hygiene

- Commit messages: English, Conventional Commits (feat: / fix: / docs: / chore: / refactor:).
- Never commit: .env, secrets, .DS_Store, __pycache__/, *.pyc.
- Agent shells are stateless: single-shot invocations (for example `conda run -n <env> ...`), never session state (`conda activate`).
