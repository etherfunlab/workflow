# frontend

From the principles: Constraints first, One source of truth.

## What it is

A repo template for frontend projects, layered on base: five spec files, plus a section merged into AGENTS.md.

| File | Governs |
|---|---|
| `DESIGN.md` | The visual constitution: surface levels, the token contract, breakpoints, alignment, motion, the verification matrix, spacing |
| `FONTS.md` | Font families and supply, weight tiers by role, sizes |
| `GRID.md` | Container and columns of the public pages (landing, legal, changelog) |
| `LOCALE.md` | All user-visible copy and the i18n workflow: sources and fallback, key names, tone, glossary, the error pattern, hard constraints for translators, machine gates |
| `RELEASE.md` | Release notes and versions: what gets an entry, version rules, format, categories, voice |
| `AGENTS.md` | Merged into the base AGENTS.md: the five specs join the reading index, plus a "Frontend" section on building and verifying |

## Why

Looks and copy are where agents drift most in a frontend. Restyle by feel ten times and you get ten styles. Written criteria that review ticks give the agent something to check against. There are five files because the five jobs come up at different times: DESIGN for a style change, FONTS for a weight, GRID for a public page layout, LOCALE for copy, RELEASE for shipping. None repeats another, and values are stored once, in the tokens file.

## How to use it

The specs hold only the rules and section skeleton that carry over between products. Product values (colors, weight numbers, breakpoints, locales, the version scheme) are `TODO:` blanks. After wiring it in, fill DESIGN.md's token table and breakpoints first, then FONTS.md. Filling a blank is a design decision: run brainstorming, and don't let the agent invent values.

Section numbers are anchors: code comments cite `DESIGN.md §4`, numbers are never changed, and a new section takes the next number.

## What gets installed

The six files above, at the repo root. In an existing project, a spec file that already exists is skipped and named in the report. AGENTS.md is merged: rows join the table with the same heading, and the "Frontend" section is appended.

## Dependencies

None.
