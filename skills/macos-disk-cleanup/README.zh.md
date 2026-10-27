# macos-disk-cleanup

给在 Mac 上做开发、硬盘常被编译产物和缓存塞满的人用。只支持 macOS。

## 这是什么

两个 skill，硬盘快满时用：

- `cleaning-dev-build-artifacts` 清编译产物：Rust 的 `target/`，以及 Claude Code 开的 worktree。附一个只读的扫描脚本 `scan.sh`，给每个 worktree 判 `REMOVE` 或 `KEEP`，并给出每个 `target/` 该用哪个 toolchain 的 cargo 来清。
- `cleaning-dev-caches` 清能重新下载的缓存：Homebrew、各家包管理器、Gradle、Playwright 浏览器、Edge 和 VS Code 的更新残留、过期的模拟器 dyld cache、没在用的 Rust toolchain。

## 为什么

能整块腾出来的空间大多在这几处，而且都能重建，代价只是下次编译或下载慢一点。难在判断此刻能不能删：worktree 里可能有没提交的改动（包括被 git 配置藏起来的未跟踪文件），或者 PR 合并后又加了本地提交；缓存可能正被某个进程用着；当前系统版本的模拟器 dyld cache 删了会原样重建，一点空间也腾不出来。两个 skill 把这些前提写成逐项检查，前提不满足就跳过，并说明原因；查不清的（比如 `git status` 报错）一律按不能删处理。删除被权限检查拦下时，agent 不换写法绕过去，把命令交给你自己跑。

## 怎么用

说「硬盘满了」「清编译产物」「清缓存」，agent 按 description 加载对应的 skill。它先扫描再删，最后报告每一项腾出了多少空间。同步盘、下载、桌面、照片库这类个人数据只列出来，不删。

## 装进你仓里的是什么

skills `cleaning-dev-build-artifacts`（连同 `scan.sh`）和 `cleaning-dev-caches`，装在你选的 skills 目录。占位符 `DEV_ROOT` 填放各个仓的目录，默认 `~/dev`。这两个 skill 管的是整台机器，装在用户级更合适。

## 依赖

macOS 和 `git`；判断分支的 PR 是否已合并要用 `gh`。表里的其他命令（brew、pnpm、rustup、xcrun 等）没装的，那一行就跳过。
