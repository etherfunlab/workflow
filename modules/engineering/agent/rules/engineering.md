# Engineering rules

- **KISS.** Three similar blocks of code beat one premature abstraction. No extension points for requirements that do not exist yet, and no defensive checks against trusted internal code.
- **One fact, one authoritative source.** Every fact (a value, a state, a condition) lives in one place; everything else derives from it through a view, a computation or a join. Prefer one more derived query over one more redundant column.
- **Schema comes from migration files; interfaces come from code.** Do not maintain copies of either in documentation; link to the source.
- **Reuse an interface before adding one.** Before adding an endpoint or interface, search for an existing one that does the job. When it is unclear whether logic belongs in frontend middleware or behind a backend endpoint, ask the user before writing it.
- **Tuning lowers the error rate; it does not chase zero.** Driving errors to zero fits the noise of the current corpus and breaks on the next one. A metric that held level is not a to-do.
- **Read live state from releases, not branches.** Check the deploy or release list to know what is running, and decide the rollback path before deploying.
- **Compare regressions by the set of failing test names, not by the count.** An equal count can hide a new regression offset by a flaky test that happened to pass; run the same command on a baseline checked out in a separate worktree.
