# RELEASE.md — release notes and versions

> Governs the release notes users read (an in-app changelog, an updates page, store notes) and how versions are numbered. Release notes answer one question: what changed for the reader. How it was built belongs in commits and PRs.
> Release notes are user-visible copy, so `LOCALE.md` applies to them in full: tone, glossary, locales, workflow.

## 0. Quick checklist (tick each in review)

1. Every user-visible change since the last release has an entry; nothing else does (§1).
2. The version follows §2 and is written in one place.
3. Entries sit in the §4 categories, in their order; empty categories are omitted.
4. Each entry says what the user can now do or no longer runs into, in the voice of §5.
5. No internal terms, ticket numbers, PR links or names of people (§5).
6. Every required locale has the note when it ships (§6).

## 1. What gets an entry

- A change a user can see or feel: a new feature, a changed behavior, a fixed bug they could have hit, a removed feature, a price or limit change.
- No entry for refactors, dependency bumps, CI, tests, internal tools, or a fix to something no user ever saw.
- One entry, one change. A change that touched many PRs is still one entry; one PR with two visible changes is two entries.
- Removals and price or limit changes are never left out, even when small.

## 2. Versions

TODO: pick one scheme and delete the other.

**Date versions** (a continuously deployed web app): a release is named by its date, TODO: format (for example `YYYY-MM-DD`). Two releases on one day get a suffix: TODO.

**Semantic versions** (`MAJOR.MINOR.PATCH`; anything others install or build against: an app in a store, a package, an API):

- MAJOR: something users or integrators relied on stops working or must be changed on their side.
- MINOR: something new, backward compatible.
- PATCH: fixes only.
- A store build number only goes up, and never repeats across version names.

Either way:

- The version is written in one place (TODO: for example `package.json` or the git tag `vX.Y.Z`); everything else reads it from there.
- A version is never reused, even for a release that was pulled.

## 3. Format

TODO: where notes live (for example `content/changelog/<locale>.json` keyed by version, or `CHANGELOG.md`) and how they are rendered.

Each release:

- **Version and date.**
- **Title**: one line naming the release's most important change for users. Not "Bug fixes and improvements".
- **Entries** under the §4 categories, one short sentence each, at most two.
- A link to a help page when a change needs explaining; the explanation does not go in the note.

## 4. Categories

In this order; a category with no entries is omitted.

| Category | For |
|---|---|
| New | Something users could not do before |
| Improved | Something that works better, faster or more clearly |
| Changed | Behavior that is different and needs the user to adjust; say what to do now |
| Fixed | A bug users could have hit, named by its symptom |
| Removed | Something that is gone; say what replaces it, if anything |

TODO: whether notes for integrators (API, SDK) keep a separate log with a "Breaking" category on top.

## 5. Voice

- Written to the user, in the form of address and tone of `LOCALE.md` §3.
- Say what changed for the reader: "You can now pin a chat to the top", not "Added pinning support to the chat list component".
- A fix names the symptom the user saw, not the cause: "Photos no longer fail to load after you switch accounts".
- No internal terms (`LOCALE.md` §4), no ticket numbers, PR links, branch names or names of people.
- No hype, no promises about future releases, no apologies longer than half a sentence.
- Numbers that changed (prices, limits) are written with their old and new value.

## 6. Workflow

- TODO: who writes the note and when (for example at release time, from the PRs merged since the last release).
- A PR with a user-visible change says so in its description, in one line a user could read; the note is assembled from those lines.
- The note ships with the release, not after it. Translations follow `LOCALE.md` §6 and must be complete for the required locales before the release goes out.
- A wrong note that has shipped is corrected in place, and the correction says what changed.

## 7. Review criteria

1. A user-visible change in the diff since the last release has no entry, or an entry describes an internal change → red.
2. An entry names the implementation, a component or an internal term instead of what the user notices → red.
3. A fix entry names a cause, not a symptom → red.
4. A removal or a price or limit change is missing → red.
5. The version breaks §2, or is written in more than one place → red.
