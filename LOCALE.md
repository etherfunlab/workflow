# LOCALE.md — languages of this repo

Which language each file is written in, and what each translation is translated from. Read it before writing or changing a README, and before adding a file.

## 1. Human-facing docs: written in Chinese

READMEs are for people. They are written in Chinese; every other language is a translation:

| Translation | Translated from |
|---|---|
| English: the `<sub>` lines, How to use and the body in `README.md`; every `README.en.md` | Chinese |
| Japanese: `README.ja.md` | Chinese |
| German: `README.de.md` | English |

- A change starts in the Chinese text and reaches every translation in the same commit, German by way of the English.
- A translation is checked against its own source, never against a sibling: Japanese against Chinese, German against English.
- The root `README.md` holds the bilingual header and How to use (Chinese first), then the English body; `README.zh.md` holds the Chinese body; `README.de.md` and `README.ja.md` each hold an intro, How to use and the full body. All four bodies keep the same `##` sections.
- Each module, skill and template has a `README.zh.md` and a `README.en.md` with the same `##` sections.
- `README.ja.md` prefers kanji (Wasei-kango and native kanji words) over katakana loanwords, and writes technical terms under their English names.

## 2. Agent-facing files: English only

`AGENTS.md`, `ADOPT.md`, this file, `module.json`, and everything under `agent/`, `setup/`, `templates/` and `tests/` apart from the READMEs of §1 are written in English, and English is their only version. Trigger phrases and quoted example words inside them stay in their own language.

A user who adopts this repo in Chinese gets the rule text translated at install time (ADOPT.md §4); that translation lives in their repo, not here.
