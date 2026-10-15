# review

出自心法：CLI 互调。

## 这是什么

让 Claude Code 当主驾，通过命令行调用 codex 来审一支分支、一个 PR 或一段 diff。codex 额度用完时，可以用同一份 prompt 调一次 OpenRouter 上的 GPT 兜底。

## 为什么

CLI 之间可以互相调用：主驾调 gh 管 PR，调 codex 审代码，调数据库 CLI 查库。审代码要换一个模型家族，同一个模型看自己写的代码，看漏的地方也是同一批。审稿模型和写稿模型必须不同。

## 怎么用

说「用 codex 审一下这支分支」或「codex review PR N」。agent 会手写一份懂这个仓的 prompt：

1. **栈事实**：模块布局、数据库和迁移纪律、diff 依赖却没有重述的旧行为。codex 看不到仓库，承重的信息都要写进来。
2. **这次改动要做什么**：一段话，让它对着意图审，不用去猜。
3. **编号的审查目标**：这个 diff 自己的不变量，比如「X 在每条路径上都成立吗」「有没有绕过 Z 去改 Y」。价值主要在这一段，通用清单代替不了。
4. **输出纪律**：只报具体缺陷，带 `file:line` 和触发它的输入或时序，按严重程度排；每个无问题的目标一行；不复述 diff，不夸。

diff 直接贴进 prompt，并明确禁止 codex 自己去翻仓库。

调用时有四个坑，每一个都会让 codex 看起来像死了，或者悄悄不出报告：

- 命令结尾要加 `</dev/null`，否则放到后台会永远等输入。
- 不要用管道接 codex 的 stdout：它会以为要读 stdin，读到 EOF 后退出 0，却不写报告文件。要日志就重定向。
- 在前台跑。放到后台、输出重定向进文件时，输出被缓冲，文件只有一行，看起来像卡住。
- `-s read-only` 要配 `-c approval_policy="never"`，否则没有 TTY 的会话会等一个永远不来的确认。

**OpenRouter 兜底按次计费。** 只在 codex 因额度用完退出时用，一次审查只发一个请求，遇到 5xx、超时或连接失败才重发同一个请求，最多两次；结果不理想就停下来交给你，不会自己改 prompt 再跑一轮。

## 装进你仓里的是什么

skill `codex-review`（含 `openrouter_review.py`），装在你选的 skills 目录。ADOPT 会问三件事：diff 对比的基准分支（默认 `origin/main`）、排除生成文件和文档用的 pathspec（默认留空，审全部）、存放 `OPENROUTER_API_KEY` 的 env 文件。

## 依赖

[codex CLI](https://github.com/openai/codex)、`python3`、`git`。兜底需要 OpenRouter 的 API key。
