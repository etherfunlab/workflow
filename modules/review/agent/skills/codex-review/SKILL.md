---
name: codex-review
description: Use when the user asks to review a branch, PR or diff with codex ("review this with codex", 用 codex 审一下, "codex review PR N"). Runs `codex exec` from the shell with a hand-written, repo-aware prompt; falls back to one OpenRouter GPT call only when codex is out of quota. Covers the invocation contract and the failure modes that make codex look dead or silently produce no report.
---

# Codex review

"Review with codex" means `codex exec` from the shell, with a prompt you write yourself that knows this repo. Do not substitute a subagent of your own model or a generic built-in review command: the point is a second model family reading the diff against this repo's own invariants.

## Invocation

```bash
codex exec -C <repoDir> -s read-only -c approval_policy="never" \
  --output-last-message "$TMPDIR/codex_review.txt" "$(cat "$TMPDIR/prompt.txt")" </dev/null
```

Read the report from the `--output-last-message` file.

## Four ways this fails silently

- **End with `</dev/null`.** It forces stdin to EOF at once. Backgrounded without it, codex waits forever.
- **Never pipe codex's stdout.** A pipe makes it think stdin is wanted; it hits EOF, exits 0, and never writes the `--output-last-message` file. For a log, redirect: `> log 2>&1 </dev/null`.
- **Run it in the foreground.** Backgrounded with `> file`, the output is buffered and the file sits at one line, which looks like a hang.
- **`-s read-only` needs `-c approval_policy="never"`.** Without it, a session with no TTY waits for an approval that never comes.

## Writing the prompt

Inline the diff and forbid exploring: "Do NOT explore the repository, do NOT open files, do NOT run commands. Review only the diff inlined below."

Four parts:

1. **Stack facts it needs.** Module layout, the database and its migration discipline, earlier behaviour the diff relies on without restating. codex cannot see the repo; anything load-bearing goes here.
2. **What the change should do.** One paragraph, so it reviews against intent instead of guessing it.
3. **Numbered review targets that are this diff's own invariants.** "Does X hold on every path", "does anything change Y without going through Z". This is where the value is; a generic checklist is not.
4. **Output discipline.** Concrete defects only, with `file:line` and the input or sequence that triggers each one, ranked by severity; one line per clean target; no summary of the diff, no praise.

The diff: `git diff {{BASE_BRANCH}}...HEAD -- {{REVIEW_GLOBS}}`.

## Fallback: OpenRouter (optional, billed per call)

Only when `codex exec` exits on a usage limit (its log ends with "You've hit your usage limit" and the output file is never written). Send the same prompt as one call:

```bash
set -a && . {{OPENROUTER_ENV_FILE}} && set +a && \
  python3 <this skill's directory>/openrouter_review.py --prompt "$TMPDIR/prompt.txt" --out "$TMPDIR/review.md"
```

- One call per review. The script retries only a 5xx or timeout of the same call. If the result is weak, stop and give it to the user; never rewrite the prompt and run again on your own.
- Before use, list `https://openrouter.ai/api/v1/models` for `openai/gpt-*`; pass `--model` when a newer flagship exists.
- Never print the key.
- Report it as what it is: codex did not run; GPT through OpenRouter did.

## Reading the result

codex reports existing behaviour as a finding when the diff makes it visible. Decide deliberately: fixing the visibility belongs in this change; fixing the old quirk itself is often a separate decision with its own blast radius. Say which one you are doing and record the other.

## Rule

The reviewer model must differ from the model that wrote the change.
