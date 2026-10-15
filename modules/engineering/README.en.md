# engineering

From the principles: Code is king, One source of truth, Watch the interfaces.

## What it is

Seven engineering rules, written into the main rule file (AGENTS.md, or CLAUDE.md when there is no AGENTS.md) so the agent reads them every session.

## Why

An agent writes code fast, so it can just as fast pile up premature abstractions, the same fact stored in two places, and interfaces nobody asked for. These rules cover the places where an agent will not hold back on its own: write less when less will do, look for something to reuse first, and judge live state from what is actually running.

## The rules

- **KISS.** Three similar blocks of code beat one premature abstraction. No extension points for requirements that do not exist yet, no defensive checks against trusted internal code.
- **One fact, one authoritative source** (from One source of truth). Each value, state or condition lives in one place; everything else derives from it through a view, a computation or a join. One more derived query beats one more redundant column.
- **Schema comes from migration files; interfaces come from code** (from Code is king). Documentation does not keep copies of either; it links to the source.
- **Look for an interface to reuse before adding one** (from Watch the interfaces). When it is unclear whether logic belongs in frontend middleware or behind a backend endpoint, ask before writing it.
- **Tuning lowers the error rate; it does not chase zero.** Driving errors to zero fits the noise of the current corpus and breaks on the next one. A metric that held level is not a to-do.
- **Read live state from releases, not branches.** The deploy or release list tells you what is running. Decide the rollback path before deploying.
- **Compare regressions by the set of failing test names, not the count.** An equal count can hide a new regression offset by a flaky test that happened to pass. Check the baseline out in a separate worktree and run the same command.

The full rules are in [`agent/rules/engineering.md`](agent/rules/engineering.md).

## What gets installed

A `## Engineering` section in the main rule file (AGENTS.md, or CLAUDE.md when there is no AGENTS.md). Where your repo already has a rule with the same meaning, ADOPT skips that one; where a rule conflicts with yours, ADOPT shows both side by side and you choose.

## Dependencies

None.
