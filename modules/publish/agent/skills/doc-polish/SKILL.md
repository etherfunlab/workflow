---
name: doc-polish
description: Use when a document for people to read has passed fact-check and its wording needs a pass before publishing — the prose reads like model output, corporate or marketing tone, or the user asks to polish it (润稿). Not for drafts whose facts are still moving.
---

# doc-polish

Stage 2 of the finishing pipeline. Change wording, never facts.

Prerequisite: `doc-fact-check` has run and its findings are fixed.

## Who runs it

The current session. The finished context is already here; sending the whole document elsewhere gains nothing.

- Chinese prose → `human-writing` skill. English prose → `humanizer` skill.
- The writing rules in this repo win over the skill's own bans (keep 「——」 and colons in technical documents; full-width commas in Chinese).
- Conservative mode for technical content: code, commands, paths, tables, English terms and parallel list items are not rewritten for variety.

## Commit the draft first

The polish diff must be reviewable on its own, separate from fact changes.

## Read sentence by sentence

Read the body from start to end and judge each sentence on its own. No search-and-replace, no replace-all: the cut lists are criteria, not a dictionary, and the same word is a term in one sentence and a violation in the next. The precheck's mechanical checks are the only pattern-based ones.

## Contrast constructions: flag, don't fix

List every "not A, but B" with its location and hand the list back to the author. Judging one needs to know whether anyone actually read A that way; that fact is outside the sentence. `doc-review` is the gate.

## Tone

Plain and restrained. No hype, no slogans, no filler. Plans for the future stay, marked as plans. Whether numbers are right is fact-check's job.

## Afterwards

Run `{{PRECHECK_PATH}} <file.md>`, then `doc-review`. Never run polish and review in parallel.
