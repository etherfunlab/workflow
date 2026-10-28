# writing

From the principle: Weak? Practice. It is the ruler people set for the agent: the agent writes by it, and people measure drafts against it in review.

## What it is

Writing and word-choice rules for every Markdown document written for people: READMEs, design docs, dev logs, release notes. Once installed, your agent loads them whenever it reads or writes a `.md` file.

## Why

Model-written prose leaves a fixed set of traces: prestige words that point at nothing, placeholder nouns standing in for concepts, signposts such as "It's worth noting" that announce structure without naming a relation, and contrast sentences that set up a straw man only to knock it down. Readers who spot these traces start skimming. The rules list them as criteria, so the agent avoids them while drafting and a reviewer has something concrete to check against.

## The rules

- **Plain verbs, precise nouns.** Short sentences, active voice, no hedging. A noun should be precise enough that no substitute fits; use the technical term when one exists (idempotent, isomorphic, convergent). Protocol names and abbreviations stay as they are.
- **Apply the cut lists as criteria.** Four lists: prestige words, placeholder nouns, figurative body-action verbs, signposts. The same word can be a term in one sentence and a violation in the next, so each sentence is read and judged on its own. No search-and-replace.
- **Name the relation between adjacent sentences.** Write but, so, then, although when the relation exists. The connective has to be true; when there is no relation, write none, and let a list look like a list.
- **Contrast constructions are blocked by default.** Write "not A, but B" only when you can name where the reading A comes from: a review comment, an earlier version, another document's conclusion, a misleading signal in real data. Without a source, A is a straw man; delete it. Quotations stay verbatim, contrast and all. Drafting and final review enforce this; polishing only flags it.
- **No padding.** State results, not slogans. Future plans are fine when marked as plans.
- **Chinese typography.** The Chinese typography rules apply to documents containing Chinese; see README.zh.md.
- **Japanese wording.** In documents containing Japanese, prefer kanji: Wasei-kango and native kanji words first, as few katakana loanwords as possible. Technical terms keep their English names (agent, commit, hook) instead of katakana transcriptions. Katakana stays only for words already in common use with no fitting kanji word.

The full rules are in [`agent/rules/writing.md`](agent/rules/writing.md).

## The constitution

Beyond the sentence level, the module ships a `WRITING.md` installed at the repo root to govern whole documents: the three questions to answer before drafting, one document one reader, the structure of a technical retrospective, bylines that state the actual division of labor, the boundaries between document types, the structural layer of AI-sounding prose (why word blacklists fall short and which syntactic frames fill empty slots — full argument [on the blog](https://blog.etherfun.xyz/posts/2026-09-02-word-blacklists-dont-stop-ai-prose)), and the load-bearing rule: **which stage of the pipeline catches which layer** — when the facts needed to judge a rule live outside the sentence, only drafting can catch it; polishing holds only the sentences, so it flags the spot and hands it back.

## What gets installed

- Claude Code: `.claude/rules/writing.md` with `paths: ["**/*.md"]`, loaded only when Markdown is read or written.
- Other agents: a section in AGENTS.md, "When editing `**/*.md`".
- Both: `WRITING.md` at the repo root, read before drafting a whole document.

## Dependencies

Polishing uses two third-party skills. This repo does not ship them: ADOPT shows the upstream link and install command and installs one only when you say yes.

- Chinese prose: [human-writing](https://github.com/Tao716/human-writing-skill)
- English prose: [humanizer](https://github.com/blader/humanizer)

In technical documents, two of this repo's rules win over human-writing's own bans:

| human-writing says | In technical documents |
|---|---|
| No dashes | Keep the Chinese dash 「——」 |
| No colons | Keep colons; tables, commands, paths and code blocks stay as they are |

Code, commands, paths, tables, English terms and parallel list items stay in conservative mode: they are not rewritten for variety.
