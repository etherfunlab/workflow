# carriers

From the principles: Repo management, One source of truth, Issues between repos.

## What it is

Where each sentence goes: what the document body, commit messages, PR and issue comments, and release notes each answer. Written into the main rule file (AGENTS.md, or CLAUDE.md when there is no AGENTS.md).

## Why

A Git repository works as memory and context store only when each kind of information has a fixed carrier. When the body carries the drafting history, readers must reconstruct the current state from a log; when evidence stays in a chat, nobody can find later why a change was made. With clear carriers, people and agents know where to look for what.

## The rules

**Carriers**

| Carrier | Answers |
|---|---|
| Document body | What is true now, and why |
| Commit message | What changed this time and on what grounds: evidence, measured numbers, the judgment it overturns |
| PR / issue comment | The conversation with people: replies to review, follow-ups, what was changed |
| Release notes | Impact downstream: breaking changes, upgrade order |

**Fix the body, or add to it**

- A fact was wrong: fix it; the reason goes in the commit message.
- A decision changed: the body keeps only the new decision; the old one and why it fell go in the commit message.
- A new fact while the old conclusion still holds: add it to the body.
- Someone already commented: fix the body and comment on what changed.
- Published and possibly cited: fix the body and mark the correction explicitly.

Files people follow step by step (migrations, deploy order, runbooks) keep their preconditions and traps in the file itself; whoever follows them will not dig through git log.

**Other rules**

- **Deliverables carry results, not process.** Code, comments and document bodies state the result and the current state, without "I verified this", "the first draft said X", "revised in v3". The one exception: a wrong statement that already reached readers is corrected explicitly.
- **Close an issue with one summary comment of four lines at most:** the capability's name, one sentence on it, the version or PR that shipped it, a link to the docs.
- **Read status from living documents.** A frozen baseline is not the current state.
- **Cross-repo problems become issues in the target repo** (from Issues between repos). Write the reproduction steps and the expected result for the agent working in that repo.

**Where documents live** (from One source of truth). ADOPT asks you for four locations: project-wide spec and docs for people, feature specs and plans, schema definitions, interface definitions. The defaults are `docs/`, `docs/superpowers/`, `migrations/*.sql`, and the code itself.

The full rules are in [`agent/rules/carriers.md`](agent/rules/carriers.md).

## What gets installed

A `## Carriers` section in the main rule file (AGENTS.md, or CLAUDE.md when there is no AGENTS.md), with the four document locations filled in from your answers.

## Dependencies

None.
