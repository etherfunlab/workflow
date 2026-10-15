---
name: doc-review
description: Use when a document for people to read has been fact-checked and polished and is one step from being pushed or published — the last gate before `git push` — or when the user asks for a final review (终审).
---

# doc-review

Stage 3, the last gate before push. Verdict: SHIP or FIX-FIRST.

## Who runs it: a different model

The reviewer must be a different model from the one that wrote the document. In Claude Code, dispatch a subagent on a different model than this session's; or run `codex-review` if it is installed. Same-model self-review does not count. If this session may not spawn subagents, ask the user for permission first.

## Run the precheck first

```bash
{{PRECHECK_PATH}} <file.md>
```

Mechanical problems should not take a person's attention.

## Seven checks

1. **Fact spot-check.** Re-verify the 3-5 claims that carry the most weight (numbers, IDs, order). Do not redo the whole fact-check.
2. **Metadata.** Frontmatter or other required fields match this repo's schema.
3. **Punctuation.** Chinese documents: full-width commas, no en-dash, 「——」 allowed.
4. **Tone.** Plain and restrained; no hype, no corporate jargon.
5. **Contrast constructions.** For each "not A, but B", ask whether the reading A can be traced to a source: a review comment, an earlier version, another document's conclusion, a misleading signal in data. If not, it is a blocker. This stage is the only gate for this rule.
6. **Scope.** Content that belongs to another document is linked, not rewritten. A reversed decision is written as a net result ("PR #A decided X"), not as a story ("first A, then B overturned A").
7. **Leaks** (public repositories). Product names, private repository names, internal URLs, local paths, personal emails. Any hit is a blocker.

## Output

```
SHIP       no blockers; push
FIX-FIRST  blockers, each with location and fix; review again after fixing
```

Blockers go to zero before the push. Non-blocking suggestions can go in the PR body.

## Next

The push step in `doc-publish`.
