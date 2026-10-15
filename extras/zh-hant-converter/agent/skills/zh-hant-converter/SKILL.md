---
name: zh-hant-converter
description: Use when Simplified Chinese text needs a Traditional Chinese version — internal team docs converted with opencc s2hk, or a product's Simplified Chinese UI copy mirrored into its Traditional Chinese locale — or when the user says 转繁, 同步繁体, or "convert to zh-Hant".
---

# zh-Hans → zh-Hant

Traditional Chinese is never written from scratch here; it is converted from the Simplified source. Decide the mode first.

| Mode | For | How |
|---|---|---|
| Internal | team docs, text agents read while working | write Simplified first, then `opencc -c s2hk`; technical terms convert character by character from the Simplified term (软件 → 軟件, 数据 → 數據) |
| External | a product's Traditional Chinese pages or locale files | glyphs, then vocabulary: mainland terms → the terms a Taiwan or Hong Kong product UI uses |

Internal mode keeps the Simplified terms because Simplified Chinese has far more technical text and its terms are nationally standardized, so agents work faster with them.

## Steps

1. Scope: convert only what this change touched: `git diff -- {{ZH_HANS_PATHS}}`.
2. Change values and body text only. Keys, structure and order stay.
3. Convert.
   - Internal: `opencc -c s2hk -i <in> -o <out>`, then check the whitelist below.
   - External: glyphs with `opencc -c s2hk` (Hong Kong) or `opencc -c s2twp` (Taiwan, which already swaps some vocabulary), then vocabulary. Common pairs (Taiwan): 信息→資訊, 视频→影片, 软件→軟體, 网络→網路, 界面→介面, 数据→資料, 登录→登入, 注销→登出, 设置→設定, 添加→加入, 访问→造訪, 恢复→復原, 通过→透過, 支持→支援, 默认→預設, 消息→訊息, 屏幕→螢幕, 点击→點按, 菜单→選單, 加载→載入. The list is not exhaustive; the test is the term a product UI in that market uses.
4. Never converted, kept verbatim: `{token}` and other placeholders, link references, brand words ({{BRAND_TERMS}}), proper nouns, URLs, email addresses, code.
5. Punctuation stays full-width; 「——」 stays.
6. Verify:
   - {{ZH_HANT_CHECK_CMD}}
   - `git diff -- {{ZH_HANT_PATHS}}` shows only the target content changed.

## Red lines

- Never edit the Simplified source. Never touch other locales.
- No polishing on the way. A tone problem is fixed in the Simplified source, then converted again.
