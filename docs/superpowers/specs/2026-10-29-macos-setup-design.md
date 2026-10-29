# macOS 环境配置脚本：设计

## 意图

新 Mac 上跑一行命令，装出一套跟维护者本机一致的工作环境：zsh 配 oh-my-zsh 与 powerlevel10k、Homebrew 装的 zsh 插件、配好字体与配色的 iTerm2，以及 agent 开发要用的 miniconda、Claude Code、Codex、Grok CLI。弱网环境另有一行命令，把能换源的下载都换到镜像。

这是仓里第一份「环境配置脚本」，放在 `setup/macos/`。以后别的系统各写一份 `setup/<os>/`，不做跨系统抽象。

模板以维护者本机的 `~/.zshrc`、`~/.oh-my-zsh`、`~/.p10k.zsh` 和 iTerm2 偏好为准。这些源文件已有备份，生成模板时只读。

## 目标

脚本跑完，机器上有：

1. Xcode Command Line Tools 与 Homebrew（`/opt/homebrew`）
2. oh-my-zsh（`~/.oh-my-zsh`），powerlevel10k 装在 `$ZSH_CUSTOM/themes/powerlevel10k`
3. brew 装的 `zsh-syntax-highlighting`、`zsh-autosuggestions`、`zsh-completions`
4. `~/.zshrc` 与 `~/.p10k.zsh` 等于仓里的模板；`~/.zprofile` 里有一行 `eval "$(/opt/homebrew/bin/brew shellenv)"`
5. brew cask `miniconda`、`claude-code@latest`、`codex`、`visual-studio-code`（`code` 命令由 cask 链接进 `/opt/homebrew/bin`）；Grok CLI 走 x.ai 官方安装器（`https://x.ai/cli/install.sh`，装进 `~/.grok`）
6. iTerm2（brew cask），新窗口默认用 MesloLGS NF 15 字体和 Ayu Mirage 配色；字体由 brew cask `font-meslo-for-powerlevel10k` 提供
7. brew `grep`（`alias grep='ggrep'` 依赖它）

## 非目标

- Linux、Windows、Intel Mac
- 登录 Claude Code / Codex / Grok（脚本结尾打印下一步）
- 改 login shell（不是 zsh 时只提示）
- iTerm2 字体与配色之外的设置：终端行为、App 级偏好、AI 功能、trigger、workgroup、窗口位置
- VS Code 的设置与扩展：只安装
- 装 pnpm、Rust、PyTorch 本体；`.zshrc` 只带它们的环境变量
- `~/.zshenv`，以及 `~/.zprofile` 里 brew 之外的行
- 持续同步 dotfiles；这不是 dotfiles 管理器
- 进 ADOPT 流程；这是装机，不是接项目

## 反目标

下面任何一条发生，即使脚本跑通也算失败：

- 用户原有的 `.zshrc` / `.p10k.zsh` 没备份就被覆盖
- omz、grok 等安装器写进 `.zshrc` 的内容留在最终的 `.zshrc` 里
- 仓里（含 commit message）出现个人信息：本机绝对路径、邮箱、私仓名、token、API 设置
- 开发或测试时在维护者本机的真实 HOME 上执行 `install.sh`
- 重复执行产生重复行、新的无谓备份或半装状态

## 启动

```bash
# 默认
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/install.sh)"

# 弱网：本仓文件走 jsDelivr，Homebrew、omz、p10k 换源
SETUP_MIRROR=jsdelivr /bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos/install.sh)"
```

- 用 `bash -c "$(curl …)"` 而不是 `curl | bash`：stdin 留给终端，Homebrew 安装器要 sudo 密码。
- 新 Mac 有 curl 没有 git，所以入口不能要求先 clone。
- 脚本自己再拉 `zshrc`、`p10k.zsh`、`iterm2-profile.json`，来源跟入口一致：默认 `https://raw.githubusercontent.com/etherfunlab/workflow/main/setup/macos/<file>`，镜像 `https://cdn.jsdelivr.net/gh/etherfunlab/workflow@main/setup/macos/<file>`。
- 脚本所在目录里已有这三个文件（在 clone 里跑、跑测试）时直接读本地，不下载。

## 各步来源

| 内容 | 默认 | `SETUP_MIRROR=jsdelivr` |
|---|---|---|
| 本仓模板文件 | raw.githubusercontent.com | jsDelivr `@main` |
| Homebrew：安装脚本、brew 仓库、API、bottles | 官方 | 国内镜像（要求见下） |
| omz 安装脚本 | raw.githubusercontent.com | `https://install.ohmyz.sh/`（omz 官方的非 GitHub 镜像） |
| omz 仓库 | GitHub | 先 GitHub；超时或失败退到 `https://gitee.com/mirrors/oh-my-zsh.git`（Gitee 自营，非官方） |
| powerlevel10k | `git clone --depth=1` GitHub（最新 master） | jsDelivr 按 `install.sh` 里写死的 commit 逐文件下载，不碰 GitHub 和 gitee |
| gitstatusd（p10k 首次启动时下载） | p10k 自带：GitHub releases，失败自动退 gitee | 同左 |
| casks（miniconda、claude-code@latest、codex、visual-studio-code、iterm2、字体）、Grok CLI | 厂商定死 | 同左，换不了 |

**Homebrew 镜像的要求**（选哪家由 builder 定）：

- 安装脚本能用 curl 直接拿，不需要 git（CLT 装好之前没有 git）
- 镜像站自己的文档写明了用法
- 用户事先设好的 `HOMEBREW_*` 变量优先，脚本不覆盖
- 镜像变量写进 `~/.zprofile` 里一段带标记的块，以后的 `brew` 继续走镜像；默认模式不写这段

**omz 回退**：GitHub clone 设超时。回退后 `origin` 留在 gitee 镜像，以后 omz 自动更新也走它。

**p10k 走 jsDelivr**：jsDelivr 不能把分支解析成 commit（`resolved?specifier=master` 返回 `null`，`@master` 的清单里没有 SHA），所以镜像模式用 `install.sh` 里写死的一个 p10k commit（`P10K_COMMIT`）。默认模式照旧 clone 最新 master，两种模式装出的版本可以不同。`@<sha>` 的内容不会变，清单与文件天然一致。GitHub HEAD `d05a1b0` 共 86 个文件、1.4 MB；`https://data.jsdelivr.com/v1/packages/gh/romkatv/powerlevel10k@<sha>?structure=flat` 的清单与 git tree 一致，按 commit 取单个文件可用。

- 按清单逐个下载到临时目录，全部成功才移到目标位置；失败不留半个目录。
- 装出来的目录不是 git 仓；要更新就删掉目录再跑脚本，拿到的是 `P10K_COMMIT` 那一版。
- `P10K_COMMIT` 由维护者手动更新，初值取实现时 GitHub 的 HEAD。

**不用 gitee 上 p10k 官方镜像的原因**：它停在 2024-11-15，比 GitHub 少 26 个 commit，缺 iTerm2 3.7+ 的 OSC 133 支持。brew 的 `powerlevel10k` formula 是 v1.20.0（2024-01），更旧。

## `.zshrc` 模板

由维护者本机 `.zshrc` 整理而来，按下面的顺序。omz 自带的、本来就注释掉的选项全部删掉；留下的非显而易见的行配一行英文注释说原因，不写日期和事故经过。

1. powerlevel10k instant prompt 块（必须在最前）
2. `ZSH="$HOME/.oh-my-zsh"`、`ZSH_THEME="powerlevel10k/powerlevel10k"`、`plugins=(git)`
3. `fpath` 加 `~/.grok/completions/zsh` 和 `/opt/homebrew/share/zsh-completions`：必须在 `source $ZSH/oh-my-zsh.sh` 之前，omz 在 source 时跑 compinit
4. `source $ZSH/oh-my-zsh.sh`
5. `~/.p10k.zsh` 存在就 source
6. `source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh`
7. conda lazy 块，原样保留：静态 export 加首次调用时才 eval 的 `conda()`，前缀 `/opt/homebrew/Caskroom/miniconda/base`
8. Homebrew 习惯：`HOMEBREW_NO_AUTO_UPDATE=1`、`HOMEBREW_CLEANUP_MAX_AGE_DAYS=7`、`alias grep='ggrep'`
9. Claude Code：`CLAUDE_CODE_REMOTE_SEND_KEEPALIVES=true`、`BUN_CONFIG_HTTP_IDLE_TIMEOUT=300`、`BUN_CONFIG_HTTP_RETRY_COUNT=3`、`CLAUDE_STREAM_IDLE_TIMEOUT_MS=120000`、`NODE_OPTIONS` 追加 `--dns-result-order=ipv4first`、`CLAUDE_CODE_THRIFTY_SONIC=0`
10. 开发工具链：`PNPM_HOME="$HOME/Library/pnpm"` 及其 PATH 段、`PYTORCH_ENABLE_MPS_FALLBACK=1`、`CARGO_PROFILE_DEV_DEBUG=line-tables-only`
11. `PATH="$HOME/.grok/bin:$PATH"`
12. `source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`，放最后（插件文档的要求）

路径一律写死 `/opt/homebrew`：与只支持 Apple Silicon 一致，shell 启动时也不用 fork `brew --prefix`。本机 `.zshrc` 里唯一不进模板的是 Supabase token 那一行。

脚本照 `zsh-completions` 的 brew caveat 执行 `chmod go-w /opt/homebrew/share` 与 `chmod -R go-w /opt/homebrew/share/zsh`：Homebrew 的 `share` 目录组可写，compaudit 会判 zsh-completions 不安全，omz 随之忽略它并报警告。

## `.p10k.zsh` 与字体

- `.p10k.zsh` 原样拷贝维护者本机的文件（向导生成，`nerdfont-v3`，没有个人信息）。
- 字体用 brew cask `font-meslo-for-powerlevel10k`，装出的四个 MesloLGS NF 文件与本机 iTerm2 实际使用的一致。`~/Library/Fonts` 里已有同名文件时跳过（cask 遇到同名文件会失败）。

## iTerm2

- `brew install --cask iterm2`
- `setup/macos/iterm2-profile.json` 是一个 Dynamic Profile：字体 `MesloLGS-NF-Regular 15`，打开 Draw Powerline Glyphs；配色是维护者本机默认 profile 的原值（含 Color Space），包括 Ansi 0–15、Foreground、Background、Bold、Cursor、Cursor Text、Cursor Guide、Selection、Selected Text、Link。Guid 新生成，不沿用本机的。
- 装到 `~/Library/Application Support/iTerm2/DynamicProfiles/`，并设为新窗口的默认 profile。预期写法是 Dynamic Profile 加 `defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string <guid>`；builder 先确认 iTerm2 认 dynamic profile 当默认，不认就在 iTerm2 首次启动前把 profile 写进它的偏好。
- iTerm2 正在运行时，写进 `defaults` 的值会在它退出时被覆盖，所以跳过设默认并提示用户；Dynamic Profile 文件会被热加载，照常放。

## 安全与幂等

- 不是 macOS、不是 arm64、以 root 运行：直接退出，不动任何文件。
- 开跑时先备份：`~/.zshrc`、`~/.p10k.zsh` 已存在且与模板不同的，各备份一份 `<file>.backup-<YYYYMMDD-HHMMSS>`；与模板相同的不备份。
- 每一步先判断是否已按设计的方式装好（对应的 brew formula / cask、`~/.oh-my-zsh` git 仓、`~/.grok/bin/grok`），装好就跳过；以别的方式装过的见下一节。
- omz 安装器用 `--unattended --keep-zshrc`：不 chsh，不自己备份，不改 `.zshrc`。
- `.zshrc` 和 `.p10k.zsh` 在所有安装器之后写，盖掉安装器追加的内容。
- `.zprofile` 里的 shellenv 行与镜像块：已有就不再加。
- 在已装好的机器上再跑一次：不改任何文件，不产生新备份。
- 结尾打印下一步：打开 iTerm2、开新 shell、`claude` 登录、`codex login`、`grok` 登录；login shell 不是 zsh 时另加提示。

## 已装过的 Mac：接管

组件以别的方式装过时，设计里的安装方式接管，旧安装不卸载：

- **app**（iTerm2、VS Code）在 `/Applications` 里但不归 brew 管：`brew install --cask --adopt` 接过来；brew 因版本不同拒绝 adopt 时用 `--force` 覆盖 app 本体（用户设置在 `~/Library`，不受影响）。
- **CLI**（claude、codex）：照装 brew 版，旧的留在原处；最终的 `.zshrc` / `.zprofile` 保证 brew 版在 PATH 上优先。新旧争同一个路径时（如 npm 全局装的 codex 也链接到 `/opt/homebrew/bin/codex`），brew 版占这个路径，旧包本身不卸载。
- **brew 内部互斥的 cask**（例如已装 `claude-code`，与 `claude-code@latest` 冲突）：卸掉旧 cask，换成设计里的那个。
- **conda**：机器上另有 Anaconda、miniforge 等时，照装 brew 的 miniconda 并存；新 `.zshrc` 的 conda 块只指向 brew 那份，旧 `.zshrc` 里的 conda init 块随备份留下。
- 结尾汇总列出：接管了哪些，哪些旧安装还留在机器上、在哪个路径。

## 交互与输出

- 全程只在开头要一次 sudo 密码：脚本先 `sudo -v`，运行期间保活，之后不再需要人。所有带确认的环节都直接同意：Homebrew 安装器 `NONINTERACTIVE=1`，omz `--unattended`，其余工具用各自的 `-y` 或等价参数。CLT 走无界面的安装方式，不弹 `xcode-select --install` 的对话框。
- 脚本不调用 conda，也就不替用户接受 Anaconda 的服务条款；第一次 `conda create` 时由用户自己确认。
- 每一步都显示进度：第几步、共几步、在做什么、结果（新装 / 已装跳过 / 接管 / 失败）。
- 下游命令的冗长输出用各自的安静参数收起来（`brew -q`、`curl -fsS`、`git -q` 等），完整输出写进日志文件；每个子项仍有一行结果，不整段静默。
- 失败时停在那一步，打印日志末尾几行和日志路径；重跑时已装好的部分自动跳过。
- 只用 ANSI 16 色加粗体、暗色，不用 256 色、真彩色和 Nerd Font 图标：首次运行在 Terminal.app 里，那时还没有 Nerd Font，也不知道用户的配色，ANSI 16 色会跟着终端主题走。stdout 不是终端或设了 `NO_COLOR` 时不输出颜色码。
- 输出文字用英文。

**样式**：Homebrew 式箭头横幅。

- 开头三行：`==> macOS setup` 后接仓名（暗色），下面 `mode` 与 `log` 两行，各缩进 4 空格；然后 sudo 的 `Password:`。
- 每步一行横幅 `==> [ n/10] <步名>`：`==>` 蓝色加粗，步名加粗，序号两位右对齐。
- 每个子项一行，缩进 4 空格，描述在左，状态词在固定列：`ok`（绿）、`done`（绿）、`skip`（暗）、`adopt`（黄）、`FAIL`（红加粗）。状态词右侧是耗时（暗，`4m10s` 格式），只有超过几秒的子项才显示。对齐用 `printf` 的宽度，整行不超过 80 列。
- 通告行（例如 GitHub 超时退到镜像、替换了互斥 cask）：黄色，缩进 4 空格，不带状态词，紧跟在相关子项之前。
- 失败：子项标 `FAIL`，空一行，红色加粗一句写命令与退出码，日志末尾三行前缀 `│`（暗），再一行 `Full log: <路径>` 和一行重跑提示；脚本以非零退出。
- 结尾：`==> Done in Xm Ys.` 绿色加粗，同一行接统计（`N installed, M already in place`）；「Earlier installs left on this Mac」列表，每行路径加一句暗色说明；「Next」编号步骤。
- 不打印正在进行的 spinner；一个子项开始时不输出，结束时输出整行。
- 候选 mock 与定稿样式的对照见 artifact「Setup Output Candidates」（候选 A）。

## 仓里放什么

| 路径 | 内容 |
|---|---|
| `setup/macos/install.sh` | 脚本，bash，注释英文 |
| `setup/macos/zshrc`、`setup/macos/p10k.zsh`、`setup/macos/iterm2-profile.json` | 模板 |
| `tests/setup-macos/run.sh` | 测试；`tests/run-all.sh` 自动跑到 |
| 四份 README 的正文 | 各加一个 `##` 节，放在补充 skills 一节之后：装了什么、两行启动命令、弱网说明 |
| `AGENTS.md` | 维护规则（见下） |

**测试**：用临时 HOME 加 PATH 里的 stub（brew、curl、git、xcode-select、uname、defaults、pgrep 等，stub 只记录调用）跑 `install.sh`，至少覆盖：

- x86_64 下退出，且没有动任何文件
- 已有 `.zshrc` 与模板不同时备份，相同时不备份
- 最终 `.zshrc` 与模板逐字节相同
- 连跑两次：shellenv 行只有一行，第二次不产生新备份
- 镜像模式请求的是镜像 URL；默认模式不请求任何镜像 URL
- 接管：不归 brew 管的 app 走 `--adopt`；`/opt/homebrew/bin/codex` 被别的包占着时 brew 版拿到该路径；已装 `claude-code` cask 时换成 `claude-code@latest`
- 镜像模式下 p10k 的每个请求都指向 `@<P10K_COMMIT>`
- stdout 不是终端时输出里没有颜色码
- `zsh -n` 检查 `zshrc` 模板，`bash -n` 检查 `install.sh`
- `setup/` 下没有 `/Users/` 这类本机绝对路径

**AGENTS.md 新增**：

- `setup/` 下的文件用英文，与 `agent/`、`templates/`、`tests/` 同列。
- `setup/` 下的改动合进 main 后，对改过的每个文件请求一次 `https://purge.jsdelivr.net/gh/etherfunlab/workflow@main/<path>`。jsDelivr 对分支引用在 CDN 上缓存 12 小时（`s-maxage=43200`），不 purge 的话，镜像模式拉到的脚本和模板可能来自不同的 commit。

## 开发纪律

- 不在维护者本机的真实 HOME 上执行 `install.sh`；测试只用临时 HOME。
- 从本机生成模板（整理 `.zshrc`、拷 `.p10k.zsh`、从 iTerm2 plist 抽配色）只读源文件。
- 干净 macOS 上的真机验证（VM 或新建用户）由维护者决定何时、在哪做；builder 不建测试用户或 VM，只写出验证步骤。iTerm2 的设定与偏好写在真实用户的 `~/Library/Preferences` 里，临时 HOME 隔离不了，所以 iTerm2 相关的行为从 iTerm2 源码确认。

## 设计者的决定（审阅时请核对）

- 目录 `setup/macos/`，文件名按上表
- 只支持 Apple Silicon，路径写死 `/opt/homebrew`
- 镜像模式由环境变量 `SETUP_MIRROR=jsdelivr` 触发
- 在 clone 里运行时读本地模板
- 已有文件先备份再覆盖；与模板相同的不备份
- `.zshrc` 删去 omz 自带的注释掉的选项；`zsh-syntax-highlighting` 挪到最后
- 字体用 `font-meslo-for-powerlevel10k`（本机 iTerm2 实际使用的字体）
- iTerm2 profile 用新 Guid；iTerm2 正在运行时跳过设默认
- 镜像模式下本仓文件跟 `@main`，不固定 commit，靠合并后 purge 保持一致
- 不进 ADOPT
- VS Code 只安装，不带设置和扩展
- 照 brew caveat 对 `/opt/homebrew/share` 去掉组写权限
- CLT 走无界面安装；脚本不调用 conda
- 输出只用 ANSI 16 色，文字用英文；子项结束时才输出整行，不做 spinner

## 留给 builder

- Homebrew 镜像站选哪家（满足上面的要求）
- omz GitHub clone 的超时值
- 读 iTerm2 源码确认默认 profile 的写法，只实现一种
- 日志文件放哪里（mock 里用的是 `~/.setup-macos/<时间戳>.log`，可改）、十个步骤怎么分组（mock 里的分法：Preflight、CLT、Homebrew、oh-my-zsh、powerlevel10k、zsh plugins、Fonts、Apps、CLIs、Dotfiles）
- 耗时显示的阈值
- 四份 README 新节的措辞（日文遵守 `README.ja.md` 的用字规则），以及 Upstream 一节要不要加 Homebrew、oh-my-zsh、powerlevel10k
- 测试 stub 的具体写法
