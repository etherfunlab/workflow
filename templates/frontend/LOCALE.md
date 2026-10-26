# LOCALE.md — copy and i18n

> The highest authority on every piece of user-visible text (i18n keys, UI literals, error messages) and on the i18n workflow. Read it before changing copy; review ticks §0.
> Rules a machine can check are enforced by tests (§8); the rest by review.

## 0. Quick checklist (tick each in review)

1. A new key lands in every TODO: required locale in the same PR (§1).
2. One form of address per language, used everywhere (§3).
3. In CJK copy, a comma or period next to a CJK character is full-width (machine gate).
4. `{token}`, plural branches and Markdown structure match the source exactly (§7).
5. Neither key names nor copy carry internal meaning: no HTTP status, no backend or vendor names (§2, §4).
6. An error message follows the one pattern and gives a way to recover (§5).
7. TODO: product checks, one line each.

## 1. Locales and sources

TODO: the locales, the default locale and the URL strategy (for example a prefix on every locale except the default).

- **Sources.** TODO: which locales are written by people and which are translated from which source (for example zh → zh-Hant / ja / ko, en → the rest). When two locales are both written by people, they state the same facts; tone and imagery may differ.
- **Fallback is the runtime chain** (TODO: where it is configured). A missing key is shown by the fallback; locale files never hold placeholder values.
- **Parity.** TODO: which locales must have exactly the source's keys on every PR, and which may lag until release (§6).
- TODO: SEO: which pages carry `hreflang` alternates, `x-default` and canonical, and where they are derived from. Derive them from the locale table, never from a hand-kept list.

## 2. Keys and files

- TODO: file layout (for example one JSON file per surface: `i18n/locales/<lang>/<surface>.json`).
- Key names follow `surface.component.element`. TODO: casing per segment.
- Name a key by what the user sees, not by how it is implemented: `error.reply_failed`, not `error.http_500`.
- TODO: syntax traps of your i18n library. For example, vue-i18n compiles messages at runtime: a literal `@` must be written `{'@'}`, and a syntax error only logs in development but blanks the whole component subtree in production.

## 3. Tone

**All languages**

- TODO: rules every language shares (for example no ellipses; an in-progress state is carried by the verb: "Generating photo").

**TODO: each source language**

- TODO: register, sentence or title case, how terse.
- One form of address per language, including serious screens (payment, legal, delete confirmations). TODO: which form, and any named exception.
- CJK punctuation is full-width next to CJK characters.

**Translated languages**

- TODO: per-language form of address where the language has more than one.

## 4. Glossary

**Never translated:** TODO: brand words, product names, terms kept in their original language.

**Internal terms never reach users** (applies to copy and to new key names):

| Internal | What users see |
|---|---|
| HTTP status, status codes, "server error" | The §5 sentence |
| Backend, upstream, vendor or model names | What the user notices ("The reply didn't arrive"), or no subject at all |
| Internal tier or plan codes | Their display names |
| TODO | |

## 5. Error messages

One pattern; new messages use it and old ones converge on it:

- en: `Couldn't <action>. <recovery>.` (for example `Couldn't load the page. Please try again later.`)
- TODO: the pattern in each other source language.
- The recovery part is dropped only when nothing can be done.
- One thing the user perceives is one sentence: errors that look the same to the user (500 / 502 / 503) share one message.

## 6. Workflow

**During development (new keys with a feature)**

1. TODO: which locales are written in the feature PR, by whom.
2. Other locales may lag; the fallback chain shows the source meanwhile. Deleting a key deletes it in every locale.
3. Review ticks §0; the machine gates (§8) run with the tests.

**Before release**

- Translate what is missing plus every key whose source changed since the last release.
- TODO: who translates which languages (people, a model, a second model family), and how languages are grouped so a group shares terminology decisions.
- Translators hand back answers only. A script validates them (§8) and writes them; a batch with one failure is not written and goes back to its translator.
- Before merging: all gates green, plus a read-through of TODO: how many translated files.

**Deleting a key** touches every locale: grep every call site first.

**Adding a language** needs its own spec.

## 7. Hard constraints for translators

Paste these into every translation prompt verbatim.

1. Do not change, add, remove or reorder keys.
2. Keep `{name}`, `{count}` and linked messages (`@:key`) exactly as they are.
3. Keep the number and position of plural branches (`|`) and translate each branch on its own. When the branches cannot carry the target language's plural forms, write the second branch in a form that does not depend on the count (`Photos: {n}`).
4. Keep Markdown (`**bold**`, `` `code` ``, `[label](url)`) and HTML structure; translate text nodes only; never translate URLs or email addresses.
5. Keep `\n` and escape sequences where they are.
6. Brand words follow §4.
7. Translate UI idioms (Save, Cancel, Loading) by the target language's UX conventions, not word for word.
8. Translate marketing lines for meaning, not words, and do not expand them: the translation is not noticeably longer than the source.
9. One file at a time; parse the JSON after each.

## 8. Machine gates

| Test | Guards |
|---|---|
| TODO: parity test | Required locales have exactly the source's keys; the rest are subsets |
| TODO: release check (pre-push or CI on the release branch) | Every locale is complete before release |
| TODO: token preservation test | `{token}` and linked messages match the source |
| TODO: copy gates | Banned forms of address, half-width commas next to CJK, ellipses, library syntax traps (§2) |
| TODO: write-back validator | Ownership of each language, keys exist, tokens and plural branches match, messages compile |

Each gate's check function has a unit test with bypass samples. A gate that only passes because the repo happens to be clean guards nothing.
