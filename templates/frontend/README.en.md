# frontend

From the principles: Constraints first, One source of truth.

## What it is

A repo template for frontend projects on Vue 3.5+ and Tailwind 4, layered on base: six spec files, plus a section merged into AGENTS.md.

| File | Governs |
|---|---|
| `DESIGN.md` | The visual constitution: surface levels, the token contract, breakpoints, alignment, motion, the verification matrix, spacing |
| `FONTS.md` | Font families and supply, weight tiers by role, sizes |
| `GRID.md` | Container and columns of the public pages (landing, legal, changelog) |
| `LOCALE.md` | All user-visible copy and the i18n workflow: sources and fallback, key names, tone, glossary, the error pattern, hard constraints for translators, machine gates |
| `RELEASE.md` | Release notes and versions: what gets an entry, version rules, format, categories, voice |
| `WRITER.md` | Who drafts each kind of user-visible text, who has the final say, and how each writer is called: interface copy, release notes, legal text, translations; the ground rules all writers share; the legal-text procedure |
| `AGENTS.md` | Merged into the base AGENTS.md: the six specs join the reading index, plus a "Frontend" section on building and verifying |

## Why

Looks and copy are where agents drift most in a frontend. Restyle by feel ten times and you get ten styles. Written criteria that review ticks give the agent something to check against. There are six files because the six jobs come up at different times: DESIGN for a style change, FONTS for a weight, GRID for a public page layout, LOCALE for copy, RELEASE for shipping, WRITER before writing any text. None repeats another, and values are stored once, in the tokens file.

The rules for copy live in LOCALE and RELEASE; WRITER only says who writes. Each kind of copy goes to a fixed writer, and the agent writes the brief, picks among candidates by the specs and runs the gates, without writing in the writer's place. Writers read LOCALE and RELEASE as written; no prompt carries a second set of rules.

## How to use it

The specs hold only the rules and section skeleton that carry over between products. Product values (colors, weight numbers, breakpoints, locales, the version scheme) are `TODO:` blanks. After wiring it in, fill DESIGN.md's token table and breakpoints first, then FONTS.md. Filling a blank is a design decision: run brainstorming, and don't let the agent invent values.

Section numbers are anchors: code comments cite `DESIGN.md §4`, numbers are never changed, and a new section takes the next number.

## What gets installed

The seven files above, at the repo root. In an existing project, a spec file that already exists is skipped and named in the report. AGENTS.md is merged: rows join the table with the same heading, and the "Frontend" section is appended.

## Dependencies

Depends on the [publish module](../../modules/publish/README.en.md): in WRITER.md, Gemini writes the interface copy of new features, through that module's `ui-copy-gemini` skill. When you choose this template, ADOPT adds publish, along with the writing module it depends on.

One third-party skill also goes with it, and this repo does not ship it: ADOPT shows the upstream link and install command and installs it only when you say yes.

- [modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance): current patterns for CSS, HTML and browser APIs, with lightweight fallbacks chosen from Baseline browser-support data, so the agent reaches for native platform features first.

It sends Google anonymous usage data by default, including the search queries the agent writes; set `DISABLE_TELEMETRY=1` in your shell profile to opt out.
