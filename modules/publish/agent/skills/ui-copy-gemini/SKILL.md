---
name: ui-copy-gemini
description: Use when a new feature, page, dialog or component needs user-visible copy — new i18n keys in the source locales, button labels, empty states, error lines, tooltips — before writing any of those strings yourself, and when asked to 写文案 / 出文案候选 / 让 Gemini 写文案. Not for translating existing keys into other locales, release notes (RELEASE.md), legal text, or fixing a word in copy that already shipped.
---

# ui-copy-gemini

Gemini drafts candidates for a new feature's copy in the source locales; you pick one per key by `LOCALE.md` (`WRITER.md` §1). Your part is the brief, one call, the picking, and landing the picks verbatim. **You never write the final copy and never rewrite a candidate.**

Needs a `LOCALE.md` laid out like the frontend template's: its §3–§5 (tone, glossary, error messages) go into the prompt verbatim. `<scratch>` is the session's scratch directory.

## Steps

1. **Write the brief** (`<scratch>/copy-brief.md`). Gemini cannot see the repo; everything it needs goes here:

   ```markdown
   # Shared albums

   A photo app. Users share an album with friends by link; friends add photos to it.
   The reader is a signed-in user on the album page. Words the page already uses: "Album", "Members", "Pro".

   ## Keys
   - `app.album.share.title` — heading of the share dialog; three words at most
   - `app.album.share.full` — one line under the link when the album is full, with {cap} (the member limit)
   - `app.album.share.copy` — the dialog's only primary button; copies the link
   ```

   - Open with what the product is, what the feature is, who sees these strings and when, and the words the same screen already uses (terms must match).
   - One line per key, ``- `key` — context``: which control it sits in, what the user must learn, a length limit, any `{token}` it must carry. A `{token}` written on that line is checked in every candidate.
   - Context states facts, not the sentence you want: put a sentence in the brief and the candidates come back as rewrites of it.
   - Key names follow `LOCALE.md` §2. A key cannot be both a leaf and the parent of another key (`a.history` and `a.history.empty` cannot coexist).

2. **One call.** Tell the user first: one paid call, how many keys, how many candidates per key. Then, from the repo root:

   ```bash
   node {{UI_COPY_DRAFT_PATH}} draft --brief <scratch>/copy-brief.md --out <scratch>/copy-candidates.json --langs <source locales>
   ```

   - `--langs`: the locales that `LOCALE.md` §1 says people write, comma-separated (`en,zh`). Locales translated or converted from them are not drafted here.
   - Three candidates per key by default (`--n`). The model is `DEFAULT_MODEL` in the script. Before running, list the `google/gemini-*` ids at `https://openrouter.ai/api/v1/models`; when a newer flagship exists, pass `--model` and update the constant.
   - The key is `OPENROUTER_API_KEY`, from the environment or `./.env`; never print it. In a worktree without `.env`: `node --env-file=<main checkout>/.env {{UI_COPY_DRAFT_PATH}} draft …`.
   - `prompt` in place of `draft` (without `--out`) prints the prompt and calls nothing.

3. **Pick one candidate per key.** `LOCALE.md` is the only yardstick, applied in this order:
   - Drop first: candidates the script's `problems` names, and any that break an item of `LOCALE.md` §0.
   - Then tone (`LOCALE.md` §3): the register, case and terseness it sets for each language.
   - Then vocabulary (`LOCALE.md` §4) and consistency across keys: one thing gets one word in every key, matching the words the brief lists.
   - Still tied: the shorter one. Take every language of a key from the same candidate; never recombine languages from different candidates.

4. **Land them.** Write the picks into the source locale files (`LOCALE.md` §2), derive any locale converted from a source (`LOCALE.md` §1) with its tool, and run the parity, token and copy gates (`LOCALE.md` §8). The other locales follow `LOCALE.md` §6, not this skill.

5. **Leave a trace**: one line in the PR description, "Copy drafted by Gemini, picked by LOCALE.md".

## A key with no acceptable candidate

Stop on that key. Land the other keys, and report these keys to the user with the reason each candidate failed; the user decides whether to draft again or handle it another way. Another draft is a new paid call, so never start one yourself. When the user agrees, the brief keeps only those keys and runs once.

## Red lines

- Never write the final copy yourself; never polish, merge or "tweak" a candidate. When nothing fits, follow the section above.
- One brief, one call. Never split a brief into several calls to get more candidates.
