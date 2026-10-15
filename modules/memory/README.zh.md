# memory

出自心法：仓库管理。

## 这是什么

把 agent 的记忆镜像进仓库。Claude Code 的 auto-memory 存在你本机的 `~/.claude/projects/<项目>/memory/`，这个模块用两个 hook 把它同步到仓里的 `.memory/`，随仓提交。

## 为什么

记忆只在维护者本机上，别的 agent 和队友就读不到这个项目攒下的约定和判断。Git 仓库本来就是记忆库加上下文库：在根目录建一个 `.memory/`，再挂上同步用的 hook 就够了，用不着另外的记忆管理系统。

## 规矩

- **本机的 auto-memory 是权威来源。** `MEMORY.md` 是它的索引，一条记忆一行，每次会话都会载入。
- **`.memory/` 是只读镜像。** 不要直接改 `.memory/` 里的文件，下次同步会覆盖；改记忆本身，让 hook 去同步。`.memory/README.md` 是镜像自己的说明，同步时保留。
- **两个 hook：**
  - PostToolUse hook（可选，仅 Claude Code）：agent 用 Write 或 Edit 写入记忆文件时，把整个记忆目录同步到 `.memory/`。
  - git pre-push hook：push 之前再同步一次，有变化就单独提交一个 `chore: sync .memory mirror`（只提交 `.memory/`，你暂存的其他改动不受影响），然后中断这次 push。这是预期行为：git 在 hook 运行前已经定下要推哪些提交，新提交要再 push 一次才会带上。
- **其他 agent 没有 auto-memory。** 那就把 `.memory/` 当成这个仓的 agent 记忆：`.memory/MEMORY.md` 做索引，一个事实一个文件、在索引里占一行，直接改、随任务提交。

完整规则在 [`agent/rules/memory.md`](agent/rules/memory.md)。

## 装进你仓里的是什么

- 主规则文件（AGENTS.md，没有的话是 CLAUDE.md）里的一节 `## Memory`，只保留和你的 agent 对应的那一半。
- `.memory/README.md`，说明这个目录是镜像。
- `.githooks/` 下的 `memory-lib.sh`、`memory-pre-push.sh` 和 `pre-push`。你还没有 pre-push hook、也没设过 `core.hooksPath` 时，ADOPT 把它设成 `.githooks`；已经有 pre-push hook 的话，ADOPT 不复制 `pre-push`，只在你的 hook 里加一行调用。
- 可选（仅 Claude Code）：`.githooks/memory-mirror.sh`，注册成 `.claude/settings.json` 里的 PostToolUse hook，追加在你已有的 hook 后面。

Claude Code 给记忆目录起名，是把仓库的绝对路径里的分隔符换成 `-`。hook 比较时，目录名和仓库路径两边都把连续的非 ASCII 字母数字字符（空格、中文都算）替换成一个 `-`；仓库路径还会用 `pwd -P` 取物理路径再比一次。所以路径里有空格、中文，或者经过符号链接，都能找到对应目录。

## 依赖

`rsync`、`jq`、`perl`。
