# etherfunlab/workflow

[简体中文](#简体中文) · [English](#english)

# 简体中文

一本用 AI agent 做开发的教科书：先讲心法，再给从心法落地的规矩和工具。出自 EtherFun Lab，写给用 agent 开发的人、刚入门的 vibe coder、junior 开发者和以后的同事。

## 主动降噪

许多外行 vibe coder 缺少一种能力：主动降噪。用热力学来比喻，就是减熵。如果没有判断力去修正 AI 的产出，放任 agent 一直跑某个任务，上下文迟早被噪声淹没。

这个仓 follow Claude 的宪法 AI 思想：先立原则、讲清理由，具体的规矩从原则里推出来。下面九条心法就是这里的原则。

> 引用：Anthropic，[Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution)（2026-01-22）；全文见 [Claude's Constitution](https://www.anthropic.com/constitution)；方法出处 [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback)（2022）。

## 心法速查

| 心法 | 一句话 |
|---|---|
| 约束优先 | 先剪枝：design → spec → plan → impl，要求越清楚，越不容易上梁不正 |
| 代码为王 | 源码是 agent 最好的说明书，别把代码压成「人类可读」的格式 |
| 仓库管理 | Git repo 就是记忆库和上下文库，同步 memory 只要 `.memory/` 加一个 hook |
| 菜就多练 | 这些判断 AI 取代不了，可以让 AI 教你，老老实实学 |
| 权威唯一 | 权威文档只存一份，在记忆里写清楚 agent 该去哪读 |
| CLI 互调 | Claude Code 当主驾，调 gh、codex、数据库 CLI、fly |
| 留心接口 | Claude Code 会不小心造接口，记忆提醒它复用，人也要盯 |
| 先聊再跑 | 需求没想清楚，先跟网页 LLM 讨论出 prompt，再跑 brainstorming |
| 跨仓开单 | 跨 repo 的问题，让 agent 开 issue 给另一个 agent 读 |

## 逐条展开

### 约束优先

剪枝。永远遵守 design → spec → plan → impl 的流程。要求提得越清楚，spec 越详细，后面越不容易上梁不正。

### 代码为王

源码是给 agent 最好的说明书。不要迷信 JSON、HTML 那些「代码可视化」，agent 读代码比你强多了；为了让人看懂而把代码压缩成人类可读的格式，反而会误导 agent。

### 仓库管理

Git repo 就是最好的记忆库加上下文库。commit 加 PR 的设计不但方便人类团队干活，也能很好地组织 agent 团队。想同步 memory，在 repo 根目录建一个 `.memory/`，再加上 post-hook 就搞定，根本不需要额外的记忆管理。

### 菜就多练

语言选择（Python、TS、Golang、Rust）、架构选择（Vue、Flutter）、部署流（Docker、K8S）、设计规范、迭代原则、工作流（需求 → schema → 接口约定 → 后端 → 前端 → E2E MVP）、网络排障、命令行指令、外语阅读能力，这些「判断」并不能被 AI 取代（但可以让 AI 教你）。老老实实学习，不要迷信那些减少信息熵的花拳绣腿。

### 权威唯一

权威文档只存一份，并且写进记忆，告诉 agent 要去哪读。一开始我建了一个文档 repo，把 spec、plan、milestone、schema、API 全放进去，后来发现字段定义东一块西一块：有的在文档库，有的在代码里，有的在项目 repo 自己的 `docs/`。后来我约定：文档库只放项目全局的 overall spec 和给人看的东西（例如我让 agent 整理的 Rust 名词对照表，方便我读懂 agent 写 Rust 时做了啥），spec 放项目自己的 `docs/superpowers/`，schema 定义只认 `migration/*.sql`，接口定义只认代码。

### CLI 互调

CLI 之间可以互相呼叫。例如 Claude Code 当主驾，可以 call gh 来管 PR 和 merge，call codex 来审代码，call `supabase db query --linked` 来查改数据库，call fly 看服务器 log 等。

### 留心接口

Claude Code 有时会不小心创造接口。除了写记忆让它记得复用接口，自己也要多留个心眼，尤其是项目变大以后，有些逻辑要用前端中间件查、有些逻辑要用后端接口时，Claude Code 不一定猜得准你的意图。

### 先聊再跑

除了 superpowers 和 gstack 这类 skill，如果不确定自己的需求怎么实现，可以先和网页版 LLM（例如 ChatGPT、Grok）讨论，让它生成 prompt，再丢给 Claude Code 跑 brainstorming，会比直接大白话咏唱强。

### 跨仓开单

GitHub issue 太好用了。现在跨 repo 的问题，我都让 agent 开 issue 给另一个 agent 读——设计给人类用的协作平台，给 agent 用同样好使，我还能追踪。

## 心法落成的做法

| 模块 | 解决什么 | 装进你仓里的 | 出自心法 |
|---|---|---|---|
| [writing](modules/writing/README.zh.md) | 写作规范、用词规范、中文排版 | `.claude/rules/writing.md`（其他 agent：AGENTS.md 一节） | 菜就多练 |
| [checkup](modules/checkup/README.zh.md) | 定期体检规则文件 | skill `rules-checkup`；可选升级提醒 hook（仅 Claude Code） | 菜就多练 |
| [rules-files](modules/rules-files/README.zh.md) | 怎么写 CLAUDE.md / AGENTS.md | `.claude/rules/rules-files.md`（其他 agent：AGENTS.md 一节） | 权威唯一 |
| [engineering](modules/engineering/README.zh.md) | 工程姿态 | AGENTS.md 一节 | 代码为王、权威唯一、留心接口 |
| [carriers](modules/carriers/README.zh.md) | 每句话写在哪 | AGENTS.md 一节 | 仓库管理、权威唯一、跨仓开单 |
| [memory](modules/memory/README.zh.md) | 记忆镜像进仓 | AGENTS.md 一节、`.memory/README.md`、`.githooks/`；同步 hook（仅 Claude Code） | 仓库管理 |
| [review](modules/review/README.zh.md) | 换一个模型家族审代码 | skill `codex-review` | CLI 互调 |
| [publish](modules/publish/README.zh.md) | 成稿收尾三道工序 | skills `doc-publish`、`doc-fact-check`、`doc-polish`、`doc-review`，`precheck.sh` | 代码为王 |
| template + [ADOPT](ADOPT.md) | 新项目骨架与接线流程 | `AGENTS.md`、`CLAUDE.md`、`docs/superpowers/`、`.workflow.lock` | 约束优先 |
| 补充：[zh-hant-converter](extras/zh-hant-converter/README.zh.md) | 简繁转换，给深港团队用 | skill `zh-hant-converter` | — |
| 补充：[ios-keyboard-page-shift](extras/ios-keyboard-page-shift/README.zh.md) | iPhone 键盘收起后页面没回来：先分层，再修 | skill `ios-keyboard-page-shift` | — |

## 怎么用

把这句话发给你的 agent：

```
读 https://github.com/etherfunlab/workflow，按 ADOPT.md 接进我的项目。
```

- **新项目**：agent 问你要哪几个模块，列出改动清单，你点头后先把 `template/` 复制过去（里面有索引式的 AGENTS.md、只有一行 `@AGENTS.md` 的 CLAUDE.md 和 `docs/superpowers/`），再装模块。
- **已有项目**：agent 先读完你现有的 CLAUDE.md、AGENTS.md、`.claude/` 和 git hooks，再问你要哪几个模块、规则用中文还是英文、skills 装在项目级还是用户级（有模块装 skill 时才问）、要不要装可选的 hook。动手之前它会列出要改的每一个文件。你仓里已有的同义规则它会跳过，冲突的规则由你选。
- **仓外的规则**：新项目和已有项目都一样，agent 会读你用户级和上层目录的规则文件。某条规则只在那里有的，它会问你跳过还是照装；跳过的话，别人 clone 这个仓，或者换一台机器、换一个 agent，那条规则就不在了。
- **更新**：装完后你的仓里有一个 `.workflow.lock`，记着装了哪些模块、对应上游哪个 commit。把这个仓再交给 agent 一次，它会拿出上游从那个 commit 到最新的改动，按模块讲给你听，你点头再合。

只有 Claude Code 才有的部分（hooks、`.claude/rules/` 路径规则）都单独标出来了。Codex 等其他 agent 会跳过 hooks，把路径规则写进 AGENTS.md。

## 依赖的上游

- [superpowers](https://github.com/obra/superpowers)：brainstorming → spec → plan → 实施的流程
- [gstack](https://github.com/garrytan/gstack)：另一套 Claude Code skill 合集
- [human-writing](https://github.com/Tao716/human-writing-skill)：中文润色
- [humanizer](https://github.com/blader/humanizer)：英文润色
- [codex CLI](https://github.com/openai/codex)：review 模块
- [OpenCC](https://github.com/BYVoid/OpenCC)：zh-hant-converter

## License

MIT，见 [LICENSE](LICENSE)。

# English

A textbook for building software with AI agents: the principles first, then the rules and tools that put them into practice. From EtherFun Lab, for developers who build with agents, new vibe coders, junior developers and future teammates.

## Active noise reduction

Many amateur vibe coders lack one skill: active noise reduction. In thermodynamic terms, it means reducing entropy. If you don't have the judgment to correct what the AI produces, and you let an agent keep running on a task, the context will sooner or later drown in noise.

This repo follows Claude's constitutional AI approach: set down the principles, explain the reasons, and derive the concrete rules from them. The nine principles below are this repo's.

> Sources: Anthropic, [Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution) (2026-01-22); full text at [Claude's Constitution](https://www.anthropic.com/constitution); the method in [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback) (2022).

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

Choosing a language (Python, TS, Go, Rust), an architecture (Vue, Flutter), a deployment flow (Docker, K8s), design guidelines, iteration principles, a workflow (requirements → schema → interface contract → backend → frontend → E2E MVP), network troubleshooting, the command line, reading in a foreign language: AI can't replace these judgments (though it can teach you). Study honestly, and don't put your faith in flashy tricks that lower information entropy.

### One source of truth

Keep one authoritative copy of each document, and write a memory that tells the agent where to read it. I started with a docs repo holding the spec, plans, milestones, schema and API. Then field definitions turned up all over the place: some in the docs repo, some in code, some in each project repo's own `docs/`. So I set a rule: the docs repo holds only the project-wide overall spec and material meant for humans (for example, a Rust glossary I had the agent compile so I could follow what it did when it wrote Rust); specs go in each project's `docs/superpowers/`; schema definitions come only from `migration/*.sql`; interface definitions come only from code.

### CLIs call CLIs

CLIs can call each other. With Claude Code as the driver, it can call gh to manage PRs and merges, codex to review code, `supabase db query --linked` to query and modify the database, fly to read server logs, and so on.

### Watch the interfaces

Claude Code sometimes invents an interface by accident. Besides writing a memory so it remembers to reuse existing interfaces, keep an eye out yourself. As the project grows and some logic belongs in frontend middleware while other logic belongs behind a backend endpoint, Claude Code won't always guess what you meant.

### Talk first, then run

Beyond skills like superpowers and gstack: if you're unsure how to implement what you want, talk it through with a web LLM (ChatGPT, Grok) first, have it write a prompt, and hand that to Claude Code to run brainstorming. That beats incanting your wish in plain words.

### Issues between repos

GitHub issues are great. For cross-repo problems, I have one agent open an issue for another agent to read. A collaboration platform built for humans works just as well for agents, and I can track all of it.

## Practices from the principles

| Module | What it solves | What lands in your repo | From the principle |
|---|---|---|---|
| [writing](modules/writing/README.en.md) | Writing and word-choice rules, Chinese typography | `.claude/rules/writing.md` (other agents: a section in AGENTS.md) | Weak? Practice. |
| [checkup](modules/checkup/README.en.md) | Periodic checkup of rule files | skill `rules-checkup`; optional upgrade-reminder hook (Claude Code only) | Weak? Practice. |
| [rules-files](modules/rules-files/README.en.md) | How to write CLAUDE.md / AGENTS.md | `.claude/rules/rules-files.md` (other agents: a section in AGENTS.md) | One source of truth |
| [engineering](modules/engineering/README.en.md) | Engineering posture | a section in AGENTS.md | Code is king, One source of truth, Watch the interfaces |
| [carriers](modules/carriers/README.en.md) | Where each sentence goes | a section in AGENTS.md | Repo management, One source of truth, Issues between repos |
| [memory](modules/memory/README.en.md) | Agent memory mirrored into the repo | a section in AGENTS.md, `.memory/README.md`, `.githooks/`; sync hook (Claude Code only) | Repo management |
| [review](modules/review/README.en.md) | Code review by a second model family | skill `codex-review` | CLIs call CLIs |
| [publish](modules/publish/README.en.md) | Three-stage finishing pipeline for docs | skills `doc-publish`, `doc-fact-check`, `doc-polish`, `doc-review`, `precheck.sh` | Code is king |
| template + [ADOPT](ADOPT.md) | New-project skeleton and the wiring procedure | `AGENTS.md`, `CLAUDE.md`, `docs/superpowers/`, `.workflow.lock` | Constraints first |
| Supplement: [zh-hant-converter](extras/zh-hant-converter/README.en.md) | Simplified → Traditional Chinese, for Shenzhen and Hong Kong teams | skill `zh-hant-converter` | — |
| Supplement: [ios-keyboard-page-shift](extras/ios-keyboard-page-shift/README.en.md) | iPhone page left pushed up after the keyboard closes: find the layer, then fix it | skill `ios-keyboard-page-shift` | — |

## How to use

Send your agent this:

```
Read https://github.com/etherfunlab/workflow and wire it into my project by following ADOPT.md.
```

- **New project**: the agent asks which modules you want and lists every change; once you say yes it copies `template/` first (an index-style AGENTS.md, a one-line `@AGENTS.md` CLAUDE.md, and `docs/superpowers/`), then installs the modules.
- **Existing project**: the agent first reads your CLAUDE.md, AGENTS.md, `.claude/` and git hooks, then asks which modules you want, whether rules should be in Chinese or English, whether skills go at project or user level (asked only when a module installs skills), and which optional hooks to install. Before writing anything it lists every file it will change. Rules your repo already has are skipped; where a rule conflicts with yours, you choose.
- **Rules outside the repo**: for new and existing projects alike, the agent reads your user-level and parent-directory rule files. When a rule exists only there, it asks whether to skip it or install it anyway; if you skip it, the rule is missing for anyone who clones the repo and on another machine or agent.
- **Update**: after installation your repo has a `.workflow.lock` recording the modules and the upstream commit. Hand this repo to your agent again; it collects the upstream changes since that commit, walks you through them module by module, and merges what you approve.

Parts that need Claude Code (hooks, `.claude/rules/` path rules) are marked. Codex and other agents skip the hooks and get path rules as sections in AGENTS.md.

## Upstream

- [superpowers](https://github.com/obra/superpowers): the brainstorming → spec → plan → implementation flow
- [gstack](https://github.com/garrytan/gstack): another Claude Code skill collection
- [human-writing](https://github.com/Tao716/human-writing-skill): Chinese polishing
- [humanizer](https://github.com/blader/humanizer): English polishing
- [codex CLI](https://github.com/openai/codex): the review module
- [OpenCC](https://github.com/BYVoid/OpenCC): zh-hant-converter

## License

MIT; see [LICENSE](LICENSE).
