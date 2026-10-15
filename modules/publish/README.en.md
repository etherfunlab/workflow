# publish

From the principle: Code is king.

## What it is

A document for people (README, dev log, design doc, release notes) goes through three stages and a mechanical precheck on its way from draft to published:

1. `doc-fact-check`: each claim is checked against code, PRs, migrations and deployed state.
2. `doc-polish`: wording changes only; facts stay.
3. `doc-review`: a different model gives the final verdict, SHIP or FIX-FIRST.

`doc-publish` runs the show: which stages, in what order, and when a push is allowed.

## Why

Source code is the best manual, so every number, ID and `file:line` in a document has to match it. The author of a fresh draft remembers the narrative, not the source; a subagent that did not write it checks the claims against the source. The final review needs a different model, because a model reviewing its own writing misses the same things every time.

## How to use it

Say "publish this doc", or ask whether a draft is ready to push.

| Situation | Stages |
|---|---|
| Still a draft | fact-check only |
| Going to published | fact-check → polish → review, in order |
| Draft whose content is all live, nothing pending | all three in one go, still in order |

Drafts often describe work that has not shipped, so the facts will still move; polishing them early is wasted.

The stages run in series: review reads the polished text. Push only after review returns SHIP. The skill lists the usual shortcuts as red flags, among them "it's short, just push it", "polish and review together saves time" and "the blocker is small, I'll fix it after pushing".

**The mechanical precheck** `precheck.sh` covers only what a regex can judge: in files containing Chinese, half-width commas next to Chinese and en-dashes; in Chinese and English, the location of contrast constructions (it points at them; a person decides). Code blocks and inline code are skipped. To change the defaults, put a `precheck.conf` next to the script (see `precheck.conf.example`):

- `ZH_CHECKS`: Chinese typography checks, on by default, applied only to files that contain Chinese.
- `CONTRAST_WARN`: list contrast constructions, on by default, never fails the run.
- `FRONTMATTER_CMD`: a command that validates frontmatter, empty by default.

## What gets installed

Four skills: `doc-publish` (with `precheck.sh` and `precheck.conf.example`), `doc-fact-check`, `doc-polish`, `doc-review`, in the skills directory you chose. ADOPT asks for two values: the path to `precheck.sh`, and the build or validation command to run before a push (it can be empty).

## Dependencies

Depends on the writing module; ADOPT adds it automatically. Polishing uses [human-writing](https://github.com/Tao716/human-writing-skill) (Chinese) and [humanizer](https://github.com/blader/humanizer) (English). The precheck needs `perl`; fact-check (line numbers at a version) and the final push need `git`.
