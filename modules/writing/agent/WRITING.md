# Writing constitution

Document-level guidance for prose written for people. The sentence-level rules live in the writing rules file; this file governs what happens before and around the sentences: positioning, structure, and which stage of the pipeline can catch which class of problem. Read it before drafting a whole document; for a small edit the rules file is enough.

## Three questions before drafting

When you cannot answer these, the document is not ready to draft:

- Which judgment does this document explain?
- Which constraints produced that judgment?
- What does the reader take away?

## One document, one reader

A document belongs to one audience, and tone, depth and terminology follow that reader:

| Reader | Tone and depth | Terms |
|---|---|---|
| Developers, future self | direct, full depth, code paths welcome | English technical terms as they are |
| Non-engineering readers (investors, the public) | confident, summary depth | everyday words, the technical term in parentheses on first use |

Internal disagreement stays in internal notes and never enters outward documents. When two audiences both seem to fit, pick the closer one and write for it alone; the other gets its own document or nothing.

## Structure of a technical retrospective

Background → abstraction (define the problem before the implementation) → constraints (latency, cost, debuggability, data boundaries, maintenance) → implementation (schema, pipeline, module boundaries or pseudocode) → trade-offs (what was given up and why that is acceptable) → applicability (who should adopt this and who should not) → current status (shipped, planned or only designed).

## Which gate catches which layer

A rule is enforced by whoever holds the facts needed to judge it:

| Facts needed | Who catches it |
|---|---|
| Character level: punctuation, format, frontmatter | a script, or polishing in passing |
| Inside the sentence: cut lists, tone, titles | polishing can fix it |
| Outside the sentence: whether a contrast has a source, whether a number is inflated, whether a plan reads as shipped | drafting must not write it; polishing only flags it and hands it back |

The third row carries the most weight. A polishing pass holds only the sentences. Forcing it to fix a problem whose facts live outside the sentence makes it reword the straw man or delete a distinction that was doing real work; both outcomes are worse than leaving the text alone. Flag the location and return it to drafting.

## The structural layer of AI-sounding prose

Word blacklists catch jargon; they do not catch syntactic frames. A model carries a set of productive frames — contrast, triple parallelism, signposting, a summary sentence closing every paragraph, dense em dashes in English — and each frame has slots that demand filling. With enough material the slots get real content; without it they get filled anyway, and the result reads like information but is not. The full argument, with public statistics: [Word blacklists don't stop AI prose](https://blog.etherfun.xyz/posts/2026-09-02-word-blacklists-dont-stop-ai-prose) ([中文版](https://blog.etherfun.xyz/zh/posts/2026-09-02-word-blacklists-dont-stop-ai-prose)).

- Contrast constructions ("not A, but B" and its family) are blocked by default; the criterion is in the sentence-level rules. Five readings of A pass: correcting a misreading a real reader would have, classifying an observation to decide its handling, marking the strength of evidence, separating two easily confused real objects, overturning a judgment you previously wrote down. Watch the English side especially: negative parallelism is the most-cited English AI trace.
- The other frames — three-item parallelism in a row, signposts, paragraph-final summaries, an em dash in every paragraph — are cut unless the material genuinely has that shape.

## Byline

The byline states the actual division of labor: who prompted, which model drafted.

## Boundaries between document types

- A dev log documents a decision, an incident or an investigation, not the steady state that resulted.
- A status report carries no mechanism detail: one line and a link to the dev log. Its length tracks how much happened, not a template.
- A standing fact that keeps changing (routing, topology, configuration) lives in a rule file or its authoritative document; reports link to it instead of restating it.
