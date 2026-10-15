# review

From the principle: CLIs call CLIs.

## What it is

Claude Code drives, and calls codex from the shell to review a branch, a PR or a diff. When codex is out of quota, the same prompt can go to a GPT model on OpenRouter as a single fallback call.

## Why

CLIs can call each other: the driver uses gh for PRs, codex for review, a database CLI for queries. A review needs a different model family; a model reading its own code misses the same things it missed while writing it. The reviewing model must differ from the writing model.

## How to use it

Say "review this branch with codex" or "codex review PR N". The agent writes a prompt that knows the repo:

1. **Stack facts**: module layout, the database and its migration discipline, earlier behaviour the diff relies on without restating. codex cannot see the repo, so anything load-bearing goes here.
2. **What the change should do**: one paragraph, so it reviews against intent instead of guessing it.
3. **Numbered review targets**: this diff's own invariants, such as "does X hold on every path" or "does anything change Y without going through Z". This is where the value is; a generic checklist cannot replace it.
4. **Output discipline**: concrete defects only, with `file:line` and the input or sequence that triggers each, ranked by severity; one line per clean target; no summary of the diff, no praise.

The diff goes into the prompt inline, and codex is told not to explore the repository.

Four traps make codex look dead or quietly skip its report:

- End the command with `</dev/null`; backgrounded without it, codex waits for input forever.
- Do not pipe codex's stdout: it decides stdin is wanted, reads EOF, exits 0 and never writes the report file. Redirect instead when you want a log.
- Run it in the foreground. Backgrounded with output redirected to a file, the output is buffered and the file sits at one line, which looks like a hang.
- `-s read-only` needs `-c approval_policy="never"`; without it, a session with no TTY waits for an approval that never comes.

**The OpenRouter fallback is billed per call.** It runs only when codex exits on its usage limit, with one request per review, re-sent only on a 5xx, a timeout or a connection failure, at most twice; a weak result goes back to you instead of into a second, rewritten round.

## What gets installed

Skill `codex-review` (with `openrouter_review.py`) in the skills directory you chose. ADOPT asks for three values: the base branch for the diff (default `origin/main`), pathspecs that keep generated files and docs out (empty by default, which reviews everything), and the env file that holds `OPENROUTER_API_KEY`.

## Dependencies

[codex CLI](https://github.com/openai/codex), `python3`, `git`. The fallback needs an OpenRouter API key.
