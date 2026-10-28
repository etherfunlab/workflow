---
paths:
  - "**/*.md"
---

# Writing rules

Applies to every Markdown document written for people to read. These are the sentence-level rules; before drafting a whole document, read the repo's `WRITING.md` for the document level — positioning, structure, and which pipeline stage catches which class of problem.

## Plain verbs, precise nouns

- Short sentences, active voice, no hedging ("maybe", "consider", 或许、建议考虑). State the conclusion.
- Every noun must be precise enough that no substitute fits. Use the technical term when one exists (idempotent, isomorphic, monotonic, convergent, orthogonal / 幂等、同构、单调、收敛、正交). Plain applies to verbs, not to nouns: the reader is a developer, not a beginner.
- Protocol names and abbreviations stay as they are (OAuth, HMAC, CSRF, JWT). Never translate them.
- Delete words that add no information. Replace words that remove information.

## Cut lists — criteria, not a dictionary

Decide each occurrence by reading its sentence: the same word is a valid term in one place and a violation in the next. Never search-and-replace.

- Prestige words that refer to nothing: 赋能、抓手、颗粒度、沉淀、打法、底层逻辑、拉齐、打通、对标; "leverage", "synergy", "empower".
- Placeholder nouns used as concept names: 东西、那一套、一个形状; "thing", "stuff". Name the actual object (artifact, change, input, problem, source).
- Figurative body-action verbs for software actions: 走、打、接、跑、落、补、收、抬、压、切、拉、推、卡. Name the actual action: call, execute, write, add, raise, switch to, blocked on. Established terms keep their verb: 接口、落盘、回滚、`git pull`, `git push`.
- Signposts that announce structure without naming a relation: 值得注意的是、此外、综上所述、首先…其次…最后; "It's worth noting", "Furthermore", "In conclusion".

## Name the relation between sentences

When two adjacent sentences stand in a logical relation, write the connective that names it: but / so / then / although (但是、因此、那么、虽然). The connective must be true. If no relation exists, write none; a list should look like a list.

## Contrast constructions are blocked by default

Do not write "not A, but B" or its family (不是 A，是 B; 不只是 A，更是 B; 并非 A，而是 B; 与其说 A，不如说 B) unless you can name a source for the reading A: a review comment, an earlier version of the document, another document's conclusion, or a misleading signal in real data. If you cannot name one, A is a straw man; delete it.

Quotations are reproduced verbatim, contrast and all.

This rule is enforced while drafting and in final review. A polishing pass only flags these sentences; it never rewrites them.

## No padding

State results. No slogans, inflated claims or filler paragraphs. Plans for the future are allowed when they are marked as plans.

## Chinese typography (documents containing Chinese)

- Full-width comma 「，」 next to Chinese text; never a half-width `,`.
- No en-dash (U+2013). Use ASCII `-` for ranges.
- The Chinese dash 「——」 is allowed.

## Japanese wording (documents containing Japanese)

- Prefer kanji: Wasei-kango (情報、概念) and native kanji words (仕組み、雛形) first; use as few katakana loanwords as possible.
- Technical terms, meaning the names of software concepts, tools and operations, keep their English names and are never transcribed into katakana: agent, commit, PR, hook, prompt, not エージェント、コミット. This holds even when the katakana form is common. Ordinary words in a technical document (文書、手順) are not technical terms.
- Keep katakana only for an ordinary word already in common use that has no fitting kanji word (チーム).

## Polishing skills

- Chinese prose → `human-writing` (https://github.com/Tao716/human-writing-skill). English prose → `humanizer` (https://github.com/blader/humanizer).
- In technical documents these rules win over the skill:
  - human-writing bans dashes: keep 「——」.
  - human-writing bans colons: keep colons. Tables, commands, paths and code blocks stay as they are.
- Conservative mode for technical content: code, commands, paths, tables, English terms and parallel list items are not rewritten for variety.
