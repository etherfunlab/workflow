# Where each sentence goes

| Carrier | Answers |
|---|---|
| Document body | What is true now, and why |
| Commit message | What changed this time and on what grounds: evidence, measured numbers, the judgment it overturns |
| PR or issue comment | The conversation with people: replies to review, follow-ups, what was changed |
| Release notes | Impact downstream: breaking changes, upgrade order |

## Fix the body or add to it

- A fact was wrong → fix it; the reason goes in the commit message.
- A decision changed → the body keeps only the new decision; the old one and why it fell go in the commit message.
- A new fact while the old conclusion still holds → add it to the body.
- Someone already commented on it → fix the body and comment on what changed.
- Published and possibly cited → fix the body and mark the correction explicitly.

Files people follow step by step (migrations, deploy order, runbooks) keep their preconditions and traps in the file itself.

## Other rules

- **Deliverables carry results, not process.** Code, comments and document bodies state the result and the current state. No "I verified this", "the first draft said X", "revised in v3". The exception: a wrong statement that already reached readers is corrected explicitly.
- **Close an issue with one summary comment of four lines at most:** the name of the capability, one sentence on it, the version or PR that shipped it, a link to the docs.
- **Read status from living documents.** A frozen baseline is not the current state.
- **Cross-repo problems become issues in the target repo.** Write the reproduction steps and the expected result so the agent working in that repo can pick it up.

## Where documents live in this project

- Project-wide overall spec and material for people: {{DOCS_GLOBAL}}
- Feature specs and plans: {{DOCS_SPECS}}
- Schema definitions: {{SCHEMA_SOURCE}}
- Interface definitions: {{API_SOURCE}}
