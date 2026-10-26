# ios-keyboard-page-shift

补充：不出自心法，给做移动端网页的团队用。

## 这是什么

排查 iPhone 上「键盘收起后页面没回来」的 skill：顶栏出了屏，输入框悬在半屏，下面空着一截。附一份参考实现，在键盘收起后把文档的滚动位置夹回可滚范围。

## 为什么

同一张截图有两种成因。iOS 为了让聚焦的输入框露在键盘上方，会滚动输入框所有可滚的祖先，也会滚动文档本身，哪一层没有回位，截图都一样。修错了层，症状原样留着，所以 skill 第一步先分层：看输入框下方那一截露出的是应用自己的背景，还是 `html` / `body` 的底色。

两层的修法不同。内层是结构问题：让本该滚动的列表成为绝对定位后代的包含块，壳层改用 `overflow: clip`。文档层是 iOS 26 起的浏览器行为，只能在键盘收起后用脚本夹回。脚本里每个条件都有用处，例如判断键盘已收起不能要求视口高度相等，因为 iOS 26 收完键盘后视口可能还短二十来像素。

## 怎么用

在 iPhone 上遇到这个症状时，agent 按 description 自动加载；也可以直接说「iOS 键盘收起后页面没回来」。参考实现 `keyboard-scroll-restore.js` 不依赖框架，在客户端每次页面加载时调用一次 `installKeyboardScrollRestore()`。

## 装进你仓里的是什么

skill `ios-keyboard-page-shift`，连同 `keyboard-scroll-restore.js`，装在你选的 skills 目录。没有要填的占位符。

## 依赖

无。只有真机 iPhone 能验证：桌面 Safari 和 Playwright WebKit 都没有软键盘。
