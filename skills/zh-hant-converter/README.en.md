# zh-hant-converter

For teams working across Shenzhen and Hong Kong.

## What it is

A skill that converts Simplified Chinese into Traditional Chinese. Traditional Chinese is never written from scratch; it always comes from the Simplified source. There are two modes; decide which one applies first.

## Why

Internal and external readers differ. Internal docs are read mostly by agents and engineers: Simplified Chinese has far more technical text and nationally standardized terms, while Hong Kong and Taiwan translations vary, so agents work faster with Simplified terms. Internal mode therefore converts glyphs only and keeps technical terms as the Simplified original. A product's Traditional Chinese pages are read by users, who expect the words their market uses, so external mode also converts vocabulary.

## How to use it

Say "convert to zh-Hant" (or 转繁 / 同步繁体).

| Mode | For | How |
|---|---|---|
| Internal | team docs, text agents read while working | write Simplified first, then `opencc -c s2hk`; technical terms convert character by character (软件 → 軟件 and 数据 → 數據) |
| External | a product's Traditional Chinese pages or locale files | glyphs first (`s2hk` for Hong Kong, `s2twp` for Taiwan, which already swaps some vocabulary), then mainland terms → the terms that market's product UIs use (Taiwan examples: 软件 → 軟體 and 数据 → 資料) |

Both modes share one discipline:

- Convert only what this change touched; change values and body text, never keys, structure or order.
- Keep the whitelist verbatim: `{token}` placeholders, link references, brand words, proper nouns, URLs, email addresses, code.
- Punctuation stays full-width; 「——」 stays.
- No polishing on the way. A tone problem is fixed in the Simplified source and converted again.
- Never edit the Simplified source; never touch other locales.
- After converting, run your check command, then read the diff to confirm only the target content changed.

## What gets installed

Skill `zh-hant-converter` in the skills directory you chose. ADOPT asks for four values: where the Simplified sources are, where the Traditional output goes, brand words that are never converted, and a check command (optional).

## Dependencies

[OpenCC](https://github.com/BYVoid/OpenCC) (macOS: `brew install opencc`), `git`.
