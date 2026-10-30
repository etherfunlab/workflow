<h1 align="center">etherfunlab/workflow</h1>

<p align="center">
  <b>一本用 AI agent 做开发的教科书</b><br>
  先讲心法，再给由心法推导出的规矩和工具。
</p>

<p align="center">
  <sub>A textbook for building software with AI agents: the principles first, then the rules and tools derived from them.</sub>
</p>

<p align="center">
  <a href="LICENSE"><img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-007ec6"></a>
  <img alt="works with: Claude Code" src="https://img.shields.io/badge/works%20with-Claude%20Code-c15f3c">
  <img alt="works with: Codex" src="https://img.shields.io/badge/works%20with-Codex-24292f">
</p>

<p align="center">
  出自 EtherFun Lab，写给工程背景的读者：<br>
  用 agent 开发的人、刚入门的 vibe coder、junior 开发者和以后的同事。<br>
  <sub>EtherFun Lab wrote it for readers with an engineering background: developers who build with agents, new vibe coders, junior developers and future teammates.</sub>
</p>

<p align="center">
  <a href="README.zh.md">简体中文全文 →</a> · <a href="#active-noise-reduction">English text below ↓</a><br>
  <a href="README.de.md">Deutsch</a> · <a href="README.ja.md">日本語</a>
</p>

## 怎么用

把这句话发给你的 agent：

```
读 https://github.com/etherfunlab/workflow，按 ADOPT.md 接进我的项目。
```

- **新项目**：agent 问你要哪几个模块和模板，列出改动清单，你点头后它先安装 `templates/base/`，添加你选的模板，再装模块。
- **已有项目**：agent 先读完你现有的 CLAUDE.md、AGENTS.md、`.claude/` 和 git hooks，再问你要哪几个模块和模板、规则用中文还是英文、skills 装在项目级还是用户级（有模块装 skill 时才问）、要不要装可选的 hook。动手之前它会列出要改的每一个文件。你仓里已有的同义规则它会跳过，冲突的规则由你选。
- **仓外的规则**：新项目和已有项目都一样，agent 会读你用户级和上层目录的规则文件。某条规则只在那里有的，它会问你跳过还是照装；跳过的话，别人 clone 这个仓，或者换一台机器、换一个 agent，那条规则就不在了。
- **更新**：装完后你的仓里有一个 `.workflow.lock`，记着装了哪些模块、对应上游哪个 commit。把 etherfunlab/workflow 再交给 agent 一次，它会找出上游从那个 commit 到最新版之间的改动，按模块讲给你听，你点头再合并。

只有 Claude Code 才有的部分（hooks、`.claude/rules/` 路径规则）都单独标出来了。Codex 等其他 agent 会跳过 hooks，把路径规则写进 AGENTS.md。

## How to use

Send your agent this:

```
Read https://github.com/etherfunlab/workflow and wire it into my project by following ADOPT.md.
```

- **New project**: the agent asks which modules and templates you want and lists every change; once you say yes it lays down `templates/base/`, layers the template you chose on top, then installs the modules.
- **Existing project**: the agent first reads your CLAUDE.md, AGENTS.md, `.claude/` and git hooks, then asks which modules and templates you want, whether rules should be in Chinese or English, whether skills go at project or user level (asked only when a module installs skills), and which optional hooks to install. Before writing anything it lists every file it will change. Rules your repo already has are skipped; where a rule conflicts with yours, you choose.
- **Rules outside the repo**: for new and existing projects alike, the agent reads your user-level and parent-directory rule files. When a rule exists only there, it asks whether to skip it or install it anyway; if you skip it, the rule won't be there for anyone who clones the repo, or when you switch to another machine or agent.
- **Update**: after installation your repo has a `.workflow.lock` recording the modules and the upstream commit. Hand etherfunlab/workflow to your agent again; it collects the upstream changes since that commit, walks you through them module by module, and merges what you approve.

Parts that need Claude Code (hooks, `.claude/rules/` path rules) are marked. Codex and other agents skip the hooks and get path rules as sections in AGENTS.md.

## Active noise reduction

Many amateur vibe coders lack one skill: active noise reduction. In thermodynamic terms, it means reducing entropy. If you don't have the judgment to correct what the AI produces, and you let an agent keep running on a task, the context will sooner or later drown in noise.

This repo follows Claude's constitutional AI approach: set down the principles, explain the reasons, and derive the concrete rules from them. The nine entries under "At a glance" are this repo's principles.

> Sources: Anthropic, [Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution) (2026-01-22); full text at [Claude's Constitution](https://www.anthropic.com/constitution); the method in [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback) (2022).

## Discipline

The discipline is widely accepted engineering practice; follow it as written. The first table is the content of the [root-directory CLAUDE.md template](templates/dev-root/README.en.md), which goes in the directory above your repositories and applies to every one of them. The second table is what the [engineering module](modules/engineering/README.en.md) installs into each repository.

**Cross-repo discipline**:

| Fact | In one line |
|---|---|
| One channel to prod, analysis repos read-only | Every repo reaches production through one encapsulated command; audit, reporting and accounting repos only read, and product repos may query and modify. Raw rows never reach the terminal or a report; aggregate locally |
| Public-repo discipline | Public issues and PRs never name private repos, internal projects or prod URLs; evidence is anonymized |
| One open PR at a time | Parallel PRs entangle, and the human pays for the conflicts; if creating a new PR is refused, stop and ask |
| Windows and eras on every number | Every reported number names its sampling window; one deploy is one era, and eras do not mix |
| Per-call APIs: one round, then stop | Calls to external APIs billed per call never iterate automatically; only transient errors of the same call are retried |
| Humans judge look-and-feel | No automated assertions on aesthetics, layout or tone; produce about three candidates side by side and stop for the human to choose |
| Investigate first, then ask | A bug report sends you to the code and logs for the cause, not back to the user for confirmation; ask only at a real fork, with options |
| Commit hygiene | Conventional Commits in English; never commit `.env` or secrets; agent shells are stateless, so use single-shot invocations such as `conda run`, never activate |

**In-repo engineering posture**:

| Fact | In one line |
|---|---|
| KISS | Three similar blocks of code beat one premature abstraction; no extension points for requirements that do not exist |
| One fact, one source | Each value, state or condition lives in one place; everything else derives |
| Schema and interfaces from source | Schema comes from migration files, interfaces from code; documentation keeps no copies |
| Reuse before adding | Look for an existing interface first; unsure between frontend and backend, ask |
| Tune down, don't chase zero | Pushing errors toward zero fits this corpus's noise; a metric holding steady is not a to-do |
| Releases, not branches | The release list says what is running; decide the rollback path before deploying |
| Regressions by failing set | Compare the set of failing test names, not the count |
| Contract before handler | Declare the interface contract before implementing it; generated API docs are artifacts, not the source of truth |
| Foreign keys at table creation | A referencing column gets its FK in the migration that creates it; nullability and ON DELETE are one decision; index every FK |
| Delete cleanly | Removed code, config and docs leave no tombstone where they were; any explanation goes in the commit message. Changelogs, migrations and runbooks still record changes. Only something actually added back after removal keeps one line, "Do not re-add X: reason Y" |

One more rule is our own position rather than consensus, and it ships in the same module: **default-open, then ratchet the gate**. Open up scope, capabilities and permissions first, and tighten once you have seen the real ceiling and actual usage. Tightening raises a threshold (a condition, a tier, a cooldown, a cost) and never removes the capability. No pre-emptive tightening before a fallback has been tested. The open phase must record measurements.

## At a glance

| Principle | In one line |
|---|---|
| Constraints first | Prune first: design → spec → plan → impl; the clearer the ask, the less goes crooked |
| Code is king | Source is the agent's best manual; don't compress code into "human-readable" formats |
| Repo management | The Git repo is the memory and context store; syncing memory takes `.memory/` plus a hook |
| Weak? Practice. | AI can't replace these judgments, but it can teach you; study honestly |
| One source of truth | Store each authoritative doc once; tell the agent in memory where to read it |
| CLIs call CLIs | Claude Code drives gh, codex, the database CLI and fly |
| Watch the interfaces | Claude Code invents interfaces; memory reminds it to reuse them, and you watch too |
| Talk first, then run | Unsure of the requirement? Work out a prompt with a web LLM, then run brainstorming |
| Issues between repos | For cross-repo problems, one agent opens an issue for another to read |

## In full

### Constraints first

Prune. Always follow design → spec → plan → impl. The clearer the requirements and the more detailed the spec, the less likely a crooked beam at the top throws off everything built below it.

### Code is king

Source code is the best manual you can give an agent. Don't put your faith in JSON or HTML "code visualizations". Agents read code far better than you do, and compressing code into a human-readable format so people can follow it ends up misleading the agent.

### Repo management

A Git repo is the best memory and context store there is. Commits and PRs help human teams get work done, and they organize teams of agents just as well. To sync memory, create a `.memory/` directory at the repo root and add a post-hook. That's all it takes; you don't need a separate memory system.

### Weak? Practice.

Choosing a language (Python, TS, Go, Rust), an architecture (Vue, Flutter), a deployment flow (Docker, K8s), design guidelines, iteration principles, a workflow (requirements → schema → interface contract → backend → frontend → E2E MVP), network troubleshooting, the command line, reading in a foreign language: AI can't replace these judgments (though it can teach you). Put in the work to learn them, and don't put your faith in flashy tricks that lower information entropy.

### One source of truth

Keep one authoritative copy of each document, and write a memory entry that tells the agent where to read it. I started with a docs repo holding the spec, plans, milestones, schema and API. Then field definitions turned up all over the place: some in the docs repo, some in code, some in each project repo's own `docs/`. So I set a rule: the docs repo holds only the project-wide overall spec and material meant for humans (for example, a Rust glossary I had the agent compile so I could follow what it did when it wrote Rust); specs go in each project's `docs/superpowers/`; schema definitions come only from `migration/*.sql`; interface definitions come only from code.

### CLIs call CLIs

CLIs can call each other. Claude Code, as the driver, can call gh to manage PRs and merges, codex to review code, `supabase db query --linked` to query and modify the database, fly to read server logs, and so on.

### Watch the interfaces

Claude Code sometimes invents an interface by accident. Write a memory entry that tells it to reuse existing interfaces, and keep an eye out yourself too. As the project grows and some logic belongs in frontend middleware while other logic belongs behind a backend endpoint, Claude Code won't always guess what you meant.

### Talk first, then run

When you're unsure how to implement what you want, skills like superpowers and gstack are one option. Another is to talk it through with a web LLM (ChatGPT, Grok) first, have it write a prompt, and hand that to Claude Code to run brainstorming. That beats incanting your wish in plain words.

### Issues between repos

GitHub issues are great. For cross-repo problems, I have one agent open an issue for another agent to read. A collaboration platform built for humans works just as well for agents, and I can track all of it.

## Practices from the principles

| Module | What it solves | What lands in your repo |
|---|---|---|
| [writing](modules/writing/README.en.md) | Writing and word-choice rules, Chinese typography, Japanese wording, a document-level writing constitution | `.claude/rules/writing.md` (other agents: a section in AGENTS.md) + `WRITING.md` at the repo root |
| [checkup](modules/checkup/README.en.md) | Periodic checkup of rule files | skill `rules-checkup`; optional reminder hook after a Claude Code upgrade |
| [rules-files](modules/rules-files/README.en.md) | How to write CLAUDE.md / AGENTS.md | `.claude/rules/rules-files.md` (other agents: a section in AGENTS.md) |
| [engineering](modules/engineering/README.en.md) | Engineering posture | a section in AGENTS.md |
| [carriers](modules/carriers/README.en.md) | Where each sentence goes | a section in AGENTS.md |
| [memory](modules/memory/README.en.md) | Agent memory mirrored into the repo | a section in AGENTS.md, `.memory/README.md`, `.githooks/`; sync hook (Claude Code only) |
| [review](modules/review/README.en.md) | Code review by a second model family | skill `codex-review` |
| [publish](modules/publish/README.en.md) | Three-stage finishing pipeline for docs | skills `doc-publish`, `doc-fact-check`, `doc-polish`, `doc-review`, `precheck.sh` |
| [Repo templates](#repo-templates) + [ADOPT](ADOPT.md) | Project skeletons and the wiring procedure | see the next section, plus `.workflow.lock` |

## Repo templates

A new project always starts from `base`, with one template for its kind of project layered on top. An existing project can take just that layer.

| Template | For | What lands in your repo |
|---|---|---|
| `base` | every new project | an index-style AGENTS.md, a one-line `@AGENTS.md` CLAUDE.md, `docs/superpowers/` |
| [frontend](templates/frontend/README.en.md) | frontend projects | `DESIGN.md`, `FONTS.md`, `GRID.md`, `LOCALE.md`, `RELEASE.md`, and a section merged into AGENTS.md |
| [dev-root](templates/dev-root/README.en.md) | the directory above several repos | a CLAUDE.md in the parent directory (cross-repo discipline; auto-loaded by Claude Code only) |

## Supplementary skills

EtherFun Lab built these skills for its own projects and keeps them in [`skills/`](skills/). When wiring, the agent lists them separately, and you install the ones you want.

| Skill | What it solves | For |
|---|---|---|
| [zh-hant-converter](skills/zh-hant-converter/README.en.md) | Simplified → Traditional Chinese: glyphs only for internal docs, vocabulary too for external use | teams across Shenzhen and Hong Kong |
| [ios-keyboard-page-shift](skills/ios-keyboard-page-shift/README.en.md) | iPhone page left pushed up after the keyboard closes: find the layer, then fix it | teams building mobile web pages |
| [macos-disk-cleanup](skills/macos-disk-cleanup/README.en.md) | Mac disk nearly full: clear build output and caches, checking each is safe to delete first | developers on a Mac |

## Environment setup

[`setup/macos/install.sh`](setup/macos/install.sh) sets up an Apple Silicon Mac the way EtherFun Lab works: Xcode Command Line Tools and Homebrew; zsh with oh-my-zsh, powerlevel10k and the zsh-syntax-highlighting, zsh-autosuggestions and zsh-completions plugins; iTerm2 with the MesloLGS NF font and an Ayu Mirage color profile; VS Code, miniconda, Claude Code, Codex and Grok CLI. It writes `~/.zshrc` and `~/.p10k.zsh` from the templates beside it, backing up existing ones that differ, and adds Homebrew to `~/.zprofile`. Apps and CLIs installed some other way are taken over by Homebrew, and the summary lists the earlier installs that stay on the machine.

On a new Mac, run this in Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)"
```

On a slow or filtered network, use the mirror mode:

```bash
SETUP_MIRROR=jsdelivr /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos/install.sh)"
```

Mirror mode fetches this repo's files from jsDelivr and Homebrew from the USTC mirror, clones oh-my-zsh from its gitee mirror when GitHub fails, and installs powerlevel10k from jsDelivr at a pinned commit. Apps, fonts and CLIs still download from their vendors. The script asks for your password once and stops at the first failure with the end of its log; the same command picks up where it stopped.

On a Mac without a graphical session, or when you only want command-line tools, add `--no-gui`: it skips iTerm2, VS Code, the font and the iTerm2 profile. The `-` fills `$0` so that the option reaches the script; you can combine the option with mirror mode.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)" - --no-gui
```

When changes under `setup/macos/` reach `main`, the installer actually runs twice with `--no-gui` on a GitHub macOS runner: the second run must install nothing.

## Upstream

- [superpowers](https://github.com/obra/superpowers): the brainstorming → spec → plan → implementation flow
- [gstack](https://github.com/garrytan/gstack): another Claude Code skill collection
- [human-writing](https://github.com/Tao716/human-writing-skill): Chinese polishing
- [humanizer](https://github.com/blader/humanizer): English polishing
- [codex CLI](https://github.com/openai/codex): the review module
- [OpenCC](https://github.com/BYVoid/OpenCC): zh-hant-converter
- [Homebrew](https://brew.sh), [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh), [powerlevel10k](https://github.com/romkatv/powerlevel10k): the environment setup script

## License

MIT; see [LICENSE](LICENSE).
