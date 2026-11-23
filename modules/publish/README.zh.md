# publish

出自心法：代码为王、权威唯一。

## 这是什么

写给人读的文档（README、开发日志、设计文档、release notes）从草稿到发出去要过三道工序，外加一个机械预检：

1. `doc-fact-check`：把文档里的说法逐条对照代码、PR、迁移文件和线上状态。
2. `doc-polish`：只改语言，不碰事实。
3. `doc-review`：换一个模型做终审，给出 SHIP 或 FIX-FIRST。

`doc-publish` 负责调度：决定做哪几道、按什么顺序、什么时候可以 push。

另有 `ui-copy-gemini`，管产品界面上的字：新功能的界面文案由 Gemini 出候选，agent 按 `LOCALE.md` 逐键挑一条，自己不写定稿，也不改候选。

## 为什么

源码是最好的说明书，文档里每个数字、编号、`file:line` 都得对得上源码。作者刚写完一篇，记得的是自己的叙述，所以核事实要交给一个没写过这篇的 subagent，拿成稿去对照源头。终审要换一个模型，因为同一个模型看自己写的东西，漏掉的总是同一批。

界面文案的规矩只在 `LOCALE.md` 存一份。出稿脚本把它的腔调、词汇、错误句式三节原文拼进 prompt，不另写一套；agent 挑候选也只拿这一份当判据。

## 怎么用

说「收尾」「发出去」，或者问「这篇能 push 了吗」。

| 情况 | 做哪几道 |
|---|---|
| 还停在草稿 | 只做 fact-check |
| 要发布 | fact-check → polish → review，按顺序 |
| 草稿内容已经全部上线、没有待办 | 三道一次做完，仍按顺序 |

草稿常写着还没发版的改动，事实还会变，太早润色就白做了。

三道必须串行：终审审的就是润色后的稿子。review 返回 SHIP 才能 push。几个常见的偷工念头在 skill 里列成了 Red flags，比如嫌稿子短就想直接 push、想把润色和终审同时做、想先 push 再修 blocker。

**机械预检** `precheck.sh` 只管正则能判断的问题：含中文的文件里，中文旁边的半角逗号和 en-dash；中英文里对比句式的位置（只标出位置，放不放行由人判断）。代码块和行内代码会跳过。要改默认行为，就在脚本旁边放一个 `precheck.conf`（照 `precheck.conf.example` 写）：

- `ZH_CHECKS`：中文排版检查，默认开，只对含中文的文件生效。
- `CONTRAST_WARN`：列出对比句式，默认开，从不导致失败。
- `FRONTMATTER_CMD`：校验 frontmatter 的命令，默认为空。

**界面文案**：新功能要加用户可见的字，或者你说「写文案」「出文案候选」，agent 就走 `ui-copy-gemini`：

1. 写 brief：产品和功能是什么、谁在什么时候看到、同页已经在用的词，每个 key 一行语境。
2. 先告诉你这是一次付费调用、出几个 key、每个 key 几条，然后调用一次 OpenRouter 上的 Gemini，默认每个 key 出 3 条候选。脚本会标出缺 key、丢了 `{token}`、中日文旁边用了半角逗号或句号的候选。
3. 按 `LOCALE.md` 逐键挑一条，原样写进 locale 文件，跑 key 对齐和 token 的闸门。

某个 key 一条合规的候选都没有，agent 就停在那里交给你，不自己补，也不擅自重跑。重跑是新的一轮付费调用。

## 装进你仓里的是什么

五个 skill：`doc-publish`（含 `precheck.sh` 和 `precheck.conf.example`）、`doc-fact-check`、`doc-polish`、`doc-review`、`ui-copy-gemini`（含出稿脚本 `draft.mjs`），装在你选的 skills 目录。ADOPT 会问三件事：`precheck.sh` 的路径，push 前要执行的构建或校验命令（可以留空），以及 `draft.mjs` 的路径。

## 依赖

依赖 writing 模块，ADOPT 会自动带上。润色用 [human-writing](https://github.com/Tao716/human-writing-skill)（中文）和 [humanizer](https://github.com/blader/humanizer)（英文）。预检要 `perl`；fact-check 按版本核行号、最后 push 要用 `git`。

`ui-copy-gemini` 要 Node 20.12 以上和 OpenRouter 的 key（环境变量或 `.env` 里的 `OPENROUTER_API_KEY`），还要一份照 [frontend 模板](../../templates/frontend/README.zh.md)写的 `LOCALE.md`。它按次计费。
