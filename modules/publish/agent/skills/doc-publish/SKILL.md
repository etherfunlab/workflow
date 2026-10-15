---
name: doc-publish
description: Use when a document for people to read (README, dev-log, design write-up, release notes) is being taken all the way out — flipped from draft to published, or pushed — or when the user says "publish this doc", 收尾, 发出去, or asks whether a draft is ready to push.
---

# doc-publish

Runs the finishing pipeline. Each stage is its own skill; this one decides which stages run, in what order, and when pushing is allowed.

- `doc-fact-check` — claims against code, PRs, migrations
- `doc-polish` — wording
- `doc-review` — final gate, by a different model

## Which stages

| Situation | Run |
|---|---|
| Staying a draft | fact-check only |
| Going to published | fact-check → polish → review |
| A draft whose content is all live, with nothing pending | all three at once |

Drafts often describe work that has not shipped yet. Polishing them early is wasted when the facts move.

## Order: serial

Never run polish and review in parallel: review reads the polished text.

## Push

```bash
{{PRECHECK_PATH}} <file.md>
{{PUBLISH_CMD}}
git push
```

Push only after `doc-review` returned SHIP.

## Red flags

- "It's short, just push it." → Length does not change the stages.
- "I'll fact-check it myself." → The author remembers the narrative, not the source.
- "Subagents aren't allowed here, so I'll self-review." → Ask the user for permission. Never replace stage 1 or 3 with self-review; stage 3 exists to switch models.
- "Polish and review together saves time." → Review reads the polished text.
- "A subagent says this is wrong, I'll change it." → When a finding conflicts with your source, verify it yourself first.
- "The blocker is small, I'll fix it after pushing." → Blockers go to zero before the push.
