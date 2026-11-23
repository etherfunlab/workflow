# WRITER.md — who writes each kind of copy, and how to call them

> Decides, for each kind of user-visible text, who drafts it, who has the final say, and where it is invoked. What the text should be is not decided here: tone, vocabulary, sentence patterns and constraints for translators are in `LOCALE.md`; what goes into release notes and how they are laid out are in `RELEASE.md`.
> Before writing, find this kind's writer in §1. For a kind the table lacks, ask the user who owns it, then add a row.
> *The agent* below is the coding agent working in this repo; the writers are the models and people in the table.

## 1. Who writes what

| Copy | Writer | Final say | Entry point |
|---|---|---|---|
| Interface copy of a new feature, source locales | Gemini drafts candidates | The agent picks one per key by `LOCALE.md` | `ui-copy-gemini` skill |
| Release notes, source locales | TODO: (for example Gemini drafts, codex polishes) | A person reads the draft | `RELEASE.md` §6 |
| Legal text | TODO: (for example codex) | A person reads the draft | §4 |
| Locales converted from a source (for example zh-Hant from zh), every kind above | TODO: the conversion tool | TODO: the gate it must pass | TODO: |
| Translated locales of interface copy and release notes | TODO: (for example codex for one group of languages, a subagent on another model for the rest) | The write-back validator (`LOCALE.md` §8) | `LOCALE.md` §6 |
| Small edits to shipped interface copy, source locales | The agent | PR review | Edit directly, following `LOCALE.md` |

- A *new feature* is a batch of keys added with a feature, page, dialog or component. One or two keys added to an existing screen, or one word changed, is a small edit.
- TODO: copy that does not go through this table (for example announcements an admin writes in a back office).

## 2. Ground rules

- **Never write in another writer's place.** For copy owned by another writer, the agent does not draft, polish or hand-edit a single line; an objection goes into the brief or prompt and back to that writer. When candidates or answers fail, stop at that item and report it to the user; never fill one in yourself.
- **The agent feeds and gatekeeps**: it writes the brief and the prompt (every fact the writer cannot see goes in), picks among candidates by the specs, runs the validators and gates, and lands the chosen text verbatim.
- **Rules live in one place.** Writers read `LOCALE.md` and `RELEASE.md` as written. To change a rule, change those files first, then run; never write a second set of rules into a prompt.
- **Never change a validator to let output through.**
- **Paid per call** (Gemini through OpenRouter): one call per batch. Before running, tell the user how many keys and how many candidates per key. Retry only a 5xx or a timeout of that same call. When the result is poor, stop and show the user; never rewrite the brief and run again.
- **On a subscription** (TODO: for example codex): use it freely. When its quota runs out, its only stand-in is TODO:; the agent and its subagents never stand in.

## 3. Calling the writers

`<scratch>` is the session's scratch directory; `<wt>` is the root of the current worktree.

**Gemini** (OpenRouter; the key is `OPENROUTER_API_KEY` in `.env`). Interface copy: the `ui-copy-gemini` skill holds the command. TODO: other Gemini jobs and their commands. Before each run, check whether OpenRouter lists a newer Gemini flagship than the default model in the script.

**codex** (TODO: delete this block when codex writes nothing in §1)

```bash
codex exec -C <wt> -s read-only -c approval_policy="never" \
  --output-last-message <scratch>/out.json - < <scratch>/prompt.md > <scratch>/codex.log 2>&1
```

Feed the prompt from a file on stdin; redirect stdout, never pipe it. One run can take more than ten minutes, so run it in the background.

TODO: one block for each other writer in §1: how to call it, where its key lives, what comes back and what validates it.

## 4. Legal text

New, changed and revised terms of service and privacy policy. TODO: which language is binding, and where the version number and effective date live.

1. **The agent writes the prompt**, with facts and a landing point only, never pre-written sentences:
   - What changed in the product: which data is collected, stored or used, who can see it, what users can do.
   - The landing point: which file, which section and paragraph, and whether to append to that paragraph, rewrite it or add a new one.
   - The languages: TODO: (for example every legal locale except those converted from a source). The binding language first; the others follow it.
   - Constraints: the form of address of `LOCALE.md` §3; as many paragraphs in each language as in the binding one; the terms, names and wording the file already uses.
   - Output: one JSON object, `{ "<lang>": "<the full text of this passage>" }`, and nothing else.
2. **Run the writer** (§3). TODO: whether it reads the current text itself (for example codex in a read-only checkout) or the prompt carries it.
3. **A person reads the draft**: TODO: which languages are shown. Continue only on a yes.
4. **Land it.** Write each language's text verbatim into TODO: the legal files, derive the converted locales from their source, and bump the version number and effective date along with the tests that pin them.
5. The release note gets an entry for the change, under a category of `RELEASE.md` §4.
