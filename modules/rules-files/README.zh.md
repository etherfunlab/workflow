# rules-files

出自心法：权威唯一。

## 这是什么

怎么写会被 agent 当指令载入的文件：CLAUDE.md、AGENTS.md、`.claude/rules/*.md`。装进你的仓以后，agent 每次改这些文件都会先读到它。

## 为什么

规则文件每次会话都整份进上下文，写进去的每个字都在和真正的任务抢注意力。事故细节、过期的墓碑、两处各写一遍的同一条规则，都是噪声。一条规则只有一个权威位置，agent 才知道该信哪一份、该去哪里读。

## 规矩

1. **写规则，不写事故现场。** 只留规则本身，理由压成一句。日期、PR 或 issue 号、行号、实测数字、复盘一律不写；证据进 commit message。
2. **删就删干净。** 不留「X 已废弃，别用」这种墓碑。唯一的例外：某个实现删掉后真的被人加回来过，才留一句「勿加回：X，原因 Y」。
3. **两层规则。** 跨仓的姿态写在上层文件；单仓的规则留在那个仓；只对某些路径有效的规则放进 `.claude/rules/`，加 `paths:` 列表，碰到对应文件时才载入。
4. **AGENTS.md 只做索引。** 它按阅读顺序说明每条规则在哪里。CLAUDE.md 只有一行：`@AGENTS.md`。
5. **「钉死，勿改」只留给用户逐字说过的约束。** 从「被纠正了好几次」推出来的规则，写成「当前实现是 X，因为 Y」。同一处被反复纠正，说明 agent 没听懂，并不说明结论该焊死。
6. **一条记忆长成了规则，就从 memory 里删掉。** 只留一份。
7. **每份规则文件只有一个权威副本。** 源文件不在 git 里时，用 hook 把它镜像进一个 git 仓留历史，永远不直接改镜像。

完整规则在 [`agent/rules/rules-files.md`](agent/rules/rules-files.md)。

## 装进你仓里的是什么

- Claude Code：`.claude/rules/rules-files.md`，`paths` 是 `**/CLAUDE.md`、`**/AGENTS.md`、`.claude/rules/**`，只在改规则文件时载入。
- 其他 agent：AGENTS.md 里的一节「When editing `**/CLAUDE.md`, `**/AGENTS.md`, `.claude/rules/**`」。
- 第 7 条的示例脚本 [`agent/scripts/mirror-rules-backup.example.sh`](agent/scripts/mirror-rules-backup.example.sh)，ADOPT 不装。你的规则文件放在不受 git 管理的目录（比如用户级的 `~/.claude/CLAUDE.md`）时才需要它：复制一份，改好路径映射，自己注册成 PostToolUse hook。

## 依赖

无。示例脚本用到 `jq`。
