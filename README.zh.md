# etherfunlab/workflow

简介和怎么用见 [README.md](README.md)。

## 主动降噪

许多外行 vibe coder 缺少一种能力：主动降噪。用热力学来比喻，就是减熵。如果没有判断力去修正 AI 的产出，放任 agent 一直执行某个任务，上下文迟早被噪声淹没。

这个仓遵循 Claude 的宪法 AI 思想：先立原则、讲清理由，具体的规矩从原则中推导出来。「心法速查」那九条就是这里的原则。

> 引用：Anthropic，[Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution)（2026-01-22）；全文见 [Claude's Constitution](https://www.anthropic.com/constitution)；方法出处 [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback)（2022）。

## 纪律

纪律是公认的工程实践，照做就行。第一张表就是[根目录 CLAUDE.md 模板](templates/dev-root/README.zh.md)的内容，装在各仓上一层的目录里，对下面每个仓都生效；第二张表由 [engineering 模块](modules/engineering/README.zh.md)安装到各仓。

**跨仓纪律**：

| 事实 | 一句话 |
|---|---|
| prod 数据唯一通道，分析类仓只读 | 所有仓查询线上数据都只用一条封装好的命令；审计、报告、账务这类仓只读，做产品的仓可以查改。原文不回显终端、不进报告，聚合在本地做 |
| 公开仓对外纪律 | 公开仓的 issue / PR 不出现私仓名、内部名、prod URL；实测证据匿名化给出 |
| 一次只开一个 PR | 两个 PR 并行内容会缠在一起，解冲突的代价归人；创建新 PR 被拒就停下来问 |
| 数字标窗口、按部署切段 | 报告里的数字必须标取数窗口；一次部署就是一个 era，跨 era 的数据不混算 |
| 花用户钱的 API 一轮一停 | 按次计费的外部 API 不自动多轮迭代；只重试同一次调用的瞬时错误 |
| 观感判官在人脑 | 观感、排版、文案语气不写自动断言；出齐约 3 个候选并排给人挑，停下等人挑是正确终点 |
| 先查后问 | 报 bug 先去代码、日志里找根因，不复述现象求确认；证据分叉才问，问就给选项 |
| 提交卫生 | commit 用英文 Conventional Commits；`.env` 和 secrets 永不入库；agent 的 shell 无状态，用 `conda run` 这类单次调用，不用 activate |

**仓内工程姿态**：

| 事实 | 一句话 |
|---|---|
| KISS | 三处相似代码胜过一个早产的抽象；不为还没出现的需求留扩展点 |
| 一个事实一个权威源 | 数值、状态、判定条件各定一处，其余一律派生 |
| schema 与接口只认源码 | schema 以迁移文件为准，接口以代码为准，文档不存副本 |
| 先复用再新增接口 | 加接口前先找现成的；拿不准放前端还是后端就先问 |
| 调参降错不清零 | 逼近零是在拟合这批语料的噪声；指标持平不是待办 |
| 看发布不看分支 | 线上跑的是哪一版看发布列表；部署前先想好回滚路径 |
| 回归比失败集合 | 看失败用例的名字集合，不看条数 |
| 契约先行 | 先声明接口契约再写实现；生成出来的 API 文档是产物，不是真相源 |
| 外键建表时就定 | 引用列建表那次就加外键；可空性与 ON DELETE 一起定；每个外键配索引 |
| 删就删干净 | 删掉的代码、配置、文档不在原处留墓碑，要交代就写进 commit message；changelog、迁移、runbook 照常记录变更；删后真被加回来过的，才留一句「勿加回：X，原因 Y」 |

还有一条是我们的主张，不算公认，一并装在 engineering 模块里：**先放再收**。尺度、能力、权限先放开使用，看清真实上限和实际用法再收。收的是门槛（条件、档位、冷却、代价），不是把能力拔掉。没有实测过的兜底，不提前收紧。放开那一步要留下测量值。

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

Git repo 就是最好的记忆库加上下文库。commit 加 PR 的设计不但方便人类团队干活，也能很好地组织 agent 团队。想同步 memory，在 repo 根目录建一个 `.memory/`，再加上 post-hook 就能同步，根本不需要额外的记忆管理。

### 菜就多练

语言选择（Python、TS、Golang、Rust）、架构选择（Vue、Flutter）、部署流（Docker、K8S）、设计规范、迭代原则、工作流（需求 → schema → 接口约定 → 后端 → 前端 → E2E MVP）、网络排障、命令行指令、外语阅读能力，这些「判断」并不能被 AI 取代（但可以让 AI 教你）。老老实实学习，不要迷信那些减少信息熵的花拳绣腿。

### 权威唯一

权威文档只存一份，并且写进记忆，告诉 agent 要去哪读。一开始我建了一个文档库，把 spec、plan、milestone、schema、API 全放进去，后来发现字段定义散在各处：有的在文档库，有的在代码里，有的在项目 repo 自己的 `docs/`。于是我约定：文档库只放项目全局的 overall spec 和给人看的文档，spec 放项目自己的 `docs/superpowers/`，schema 定义只认 `migration/*.sql`，接口定义只认代码。我让 agent 整理的 Rust 名词对照表就属于给人看的文档，方便我读懂 agent 写 Rust 时做了什么。

### CLI 互调

CLI 之间可以互相调用。例如 Claude Code 当主驾，可以调用 gh 管理 PR 和 merge，调用 codex 审代码，调用 `supabase db query --linked` 查询和修改数据库，调用 fly 查看服务器 log 等。

### 留心接口

Claude Code 有时会不小心造出新接口。写记忆提醒它复用现有接口之外，你自己也要多留个心眼。项目变大以后，有些逻辑该由前端中间件查，有些该由后端接口提供，Claude Code 不一定猜得准你要哪一种。

### 先聊再跑

不确定需求怎么实现时，除了用 superpowers、gstack 这类 skill，还可以先和网页版 LLM（例如 ChatGPT、Grok）讨论，让它生成 prompt，再交给 Claude Code 执行 brainstorming。这比直接用大白话咏唱强。

### 跨仓开单

GitHub issue 太好用了。现在跨 repo 的问题，我都让 agent 开 issue 给另一个 agent 读——设计给人类用的协作平台，给 agent 用同样好使，我还能追踪。

## 心法落成的做法

| 模块 | 解决什么 | 装进你仓里的 |
|---|---|---|
| [writing](modules/writing/README.zh.md) | 写作规范、用词规范、中文排版、日文用字、篇级写作宪法 | `.claude/rules/writing.md`（其他 agent：AGENTS.md 一节）＋ 仓根 `WRITING.md` |
| [checkup](modules/checkup/README.zh.md) | 定期体检规则文件 | skill `rules-checkup`；可选的 Claude Code 升级后提醒 hook |
| [rules-files](modules/rules-files/README.zh.md) | 怎么写 CLAUDE.md / AGENTS.md | `.claude/rules/rules-files.md`（其他 agent：AGENTS.md 一节） |
| [engineering](modules/engineering/README.zh.md) | 工程姿态 | AGENTS.md 一节 |
| [carriers](modules/carriers/README.zh.md) | 每句话写在哪 | AGENTS.md 一节 |
| [memory](modules/memory/README.zh.md) | 记忆镜像进仓 | AGENTS.md 一节、`.memory/README.md`、`.githooks/`；同步 hook（仅 Claude Code） |
| [review](modules/review/README.zh.md) | 换一个模型家族审代码 | skill `codex-review` |
| [publish](modules/publish/README.zh.md) | 成稿收尾三道工序 | skills `doc-publish`、`doc-fact-check`、`doc-polish`、`doc-review`，`precheck.sh` |
| [仓库模板](#仓库模板) + [ADOPT](ADOPT.md) | 项目骨架与接线流程 | 见下一节，外加 `.workflow.lock` |

## 仓库模板

新项目一律先安装 `base`，再按项目类型添加一层模板。已有项目也可以只添加后者。

| 模板 | 给谁 | 装进你仓里的 |
|---|---|---|
| `base` | 所有新项目 | 索引式的 AGENTS.md、只有一行 `@AGENTS.md` 的 CLAUDE.md、`docs/superpowers/` |
| [frontend](templates/frontend/README.zh.md) | 前端项目 | `DESIGN.md`、`FONTS.md`、`GRID.md`、`LOCALE.md`、`RELEASE.md`，AGENTS.md 并进一节 |
| [dev-root](templates/dev-root/README.zh.md) | 管着多个仓的上级目录 | 上一层目录的 CLAUDE.md（跨仓纪律；仅 Claude Code 自动载入） |

## 补充 skills

EtherFun Lab 做项目时积累的几个 skill，放在 [`skills/`](skills/)。接线时 agent 会单独列出它们，要哪个装哪个。

| skill | 解决什么 | 给谁 |
|---|---|---|
| [zh-hant-converter](skills/zh-hant-converter/README.zh.md) | 简繁转换：对内只转字形，对外连词汇一起换 | 深港团队 |
| [ios-keyboard-page-shift](skills/ios-keyboard-page-shift/README.zh.md) | iPhone 键盘收起后页面没回来：先分层，再修 | 做移动端网页的团队 |
| [macos-disk-cleanup](skills/macos-disk-cleanup/README.zh.md) | Mac 硬盘快满：清编译产物和缓存，每项先确认能删再删 | 在 Mac 上做开发的人 |

## 环境配置脚本

[`setup/macos/install.sh`](setup/macos/install.sh) 把一台 Apple Silicon Mac 配成 EtherFun Lab 的工作环境：Xcode Command Line Tools 和 Homebrew；zsh 配 oh-my-zsh、powerlevel10k，以及 zsh-syntax-highlighting、zsh-autosuggestions、zsh-completions 三个插件；iTerm2 配 MesloLGS NF 字体和 Ayu Mirage 配色；VS Code、miniconda、Claude Code、Codex 和 Grok CLI。`~/.zshrc` 与 `~/.p10k.zsh` 照同目录的模板写入，原有的不一样就先备份；`~/.zprofile` 加上 Homebrew。用别的方式装过的 app 和 CLI 交给 Homebrew 接管，结尾会列出还留在机器上的旧安装。

新 Mac 上打开 Terminal 运行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)"
```

网络慢或受限时用镜像模式：

```bash
SETUP_MIRROR=jsdelivr /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos/install.sh)"
```

本仓文件从 jsDelivr 下载，Homebrew 使用中科大（USTC）镜像，oh-my-zsh 在 GitHub 连不上时改从 gitee 镜像 clone，powerlevel10k 从 jsDelivr 按固定 commit 下载。app、字体和 CLI 仍从各家官方下载。脚本只在开头要一次密码，出错就停在那一步并给出日志末尾；同一条命令重跑，会从停下的地方接着装。

没有图形界面的 Mac，或只要命令行工具时，加 `--no-gui`：不装 iTerm2、VS Code 和字体，也不写 iTerm2 profile。中间的 `-` 占住 `$0`，参数才能传到脚本；可与镜像模式同用。

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)" - --no-gui
```

`setup/macos/` 下的改动进了 `main`，就在 GitHub 的 macOS runner 上加 `--no-gui` 实际执行两遍：第二遍必须什么都不装。

## 依赖的上游

- [superpowers](https://github.com/obra/superpowers)：brainstorming → spec → plan → 实施的流程
- [gstack](https://github.com/garrytan/gstack)：另一套 Claude Code skill 合集
- [human-writing](https://github.com/Tao716/human-writing-skill)：中文润色
- [humanizer](https://github.com/blader/humanizer)：英文润色
- [codex CLI](https://github.com/openai/codex)：review 模块
- [OpenCC](https://github.com/BYVoid/OpenCC)：zh-hant-converter
- [Homebrew](https://brew.sh)、[oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)、[powerlevel10k](https://github.com/romkatv/powerlevel10k)：环境配置脚本

## License

MIT，见 [LICENSE](LICENSE)。
