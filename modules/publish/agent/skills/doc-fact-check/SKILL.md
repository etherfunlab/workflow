---
name: doc-fact-check
description: Use when a document for people to read has been drafted and its claims have not yet been checked against code, PRs, migrations or deployed state — also when a draft is about to be published, or when the user asks to fact-check a doc (核一下).
---

# doc-fact-check

Stage 1 of the finishing pipeline, and the only stage a draft needs. Match what the document says against code, PRs, migrations and deployed state, claim by claim. Produce a list; do not edit the document.

## Who runs it

A read-only subagent, never the author's session: the author remembers the narrative, not the source. A cheaper model is fine. If this session may not spawn subagents, ask the user for permission; do not replace this stage with self-review.

## What to check

| Kind | Check |
|---|---|
| Code references | `file:line` exists and still shows that code; function, table, column and endpoint names are spelled right |
| Numbers and IDs | PR, issue and migration numbers, and which repo owns them; whether a PR is merged or still open |
| Time | merge, release and deploy timestamps, converted to the reader's time zone |
| Values | constants, thresholds, defaults, test counts — checked against the source, not memory |
| Order | sequences match PR descriptions and migration constraints |
| Scope | facts owned by another document (rule files, reports, other write-ups) are linked, not rewritten |
| Quotations | text in quotes is the original wording; a paraphrase or translation in quotes is wrong |
| Versions | a line number is checked against the version the sentence talks about, not the working tree |

Check a line number at a version:

```bash
git show <tag>:<path> | perl -ne 'print "$.\n" if /<pattern>/'
```

In the document, carry the version ("v1.5.0's `stream.rs:5109`") or drop the line number.

## Output

```
WRONG     §2.3 "migration 018 revoked anon"
          → 018 revoked service_role; 017 revoked anon
          evidence: migrations/018_revoke_grant.sql:18
IMPRECISE §1.5 "merged 08-21 19:38"
          → mergedAt 2026-08-21T11:38:36Z; the conversion is right but the time zone is not stated
OK        §1.1 migration number 0054
```

The author applies the fixes.

## One discipline

When a finding conflicts with the author's source, the author verifies it before changing anything. Subagents also read the wrong version or the wrong repo, or treat an open PR as merged.

## Next

- Staying a draft: stop here.
- Going to published: `doc-polish`, then `doc-review`. The whole flow is `doc-publish`.
