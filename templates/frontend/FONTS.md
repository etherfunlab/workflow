# FONTS.md — families, weights, sizes

> This file governs type: font families and how they are supplied, the weight tiers, the size scale. `DESIGN.md` is still the visual constitution; read this file whenever a change touches a weight, a size or a font stack.
> Values live only in TODO: the tokens file (`--font-weight-*`, `--font-sans*`). This file holds the rules.

## 1. Weight tiers by role

Sans text uses only the tiers below; every other weight is red. Tiers are cut by role, not importance: importance is a continuum and anyone can argue for one more tier, while a role has one answer.

| Tier | Value | Role | Where |
|---|---|---|---|
| Read | TODO | Content to be read | Body copy, descriptions, list previews, inputs, empty states; all sans text from TODO px up |
| Point | TODO | Clickable, but not a button; usually an item in a list | Row names, card names, navigation items, filter chips, inline links; small marks (badges, counts, times) follow it |
| Button | TODO | Real buttons and segmented controls | Buttons, CTAs, segmented tabs, toolbar actions |
| Name | TODO | Display-only subject that is not clickable | Page and modal titles, section titles, the header name of the thing on screen |

- **One question decides:** is it an item in a list, or the subject of this block? The same name can sit in two tiers: an item in a list (Point) and the heading of its own page (Name).
- The numbers are written once, in the tokens file. Call sites use the tier names (`font-medium`, `font-semibold`, …), so moving the whole scale touches no call site. Raw CSS uses `var(--font-weight-*)`; a number there is red.
- List rows are not layered by weight. Name, preview and time differ by size and color; when a row needs more separation, change size or color, not weight.
- Weights reach most of the UI through a few shared components (button, segmented tabs). A guard test keeps those components on their tiers.

## 2. Bigger means lighter

Hierarchy is size × weight, not the number of weight tiers.

- From TODO px up, only the two lighter tiers. To sound louder, switch to the display face (TODO: which face, and where it is allowed), not to a heavier weight.
- Small UI marks (≤ TODO px) on translucent surfaces do not use the Read tier; thin small text turns gray. Multi-line small body text is the exception.
- A state that toggles (selected, current page) is never shown by weight: the width changes and the control shifts under the pointer. Use color or a tint (`DESIGN.md` §4). A guard test scans both branches of conditional classes.
- Weight and color do not stack on one level (both heavier and darker). Muted has one level.
- No `uppercase` plus letter spacing on text that goes through i18n; CJK has no case.

## 3. Supply: every tier needs a real face

A weight tier only exists where a real font face renders it.

- System CJK faces stop short: Apple's PingFang has no weight above 600, and Windows' YaHei and JhengHei ship 300 / 400 / 700. A scale with four sans tiers needs a web font for the tiers the system lacks.
- TODO: per platform and locale, which face serves each tier:

  | Tier | Apple | Windows | Android / Linux | Web font |
  |---|---|---|---|---|
  | Read | TODO | TODO | TODO | TODO |
  | Point | TODO | TODO | TODO | TODO |
  | Button | TODO | TODO | TODO | TODO |
  | Name | TODO | TODO | TODO | TODO |

- Set `font-synthesis-weight: none` on `body`. A missing face then falls back to the nearest real one instead of a faked bold. An element that genuinely needs synthesis gets one named utility, and the files that use it are listed here and pinned by a test.
- Ship only the weights the tiers use. A request for a lighter weight then lands on the lightest tier, so the font supply itself keeps text from going thinner.
- TODO: CJK regional faces (for example whether Traditional Chinese uses the Hong Kong or Taiwan variant), and why.

## 4. Sizes

Applies to sizes you add or change; existing sizes are fixed when touched, not swept.

1. TODO: the size scale.
2. A role's size on phones is never larger than on desktop. A phone is held closer, so the same CSS pixel already looks bigger.

## 5. Review criteria

1. A weight outside the tiers (`font-black`, `font-[NNN]`), a numeric `font-weight` in raw CSS, or a change to the tier values in the tokens file → red.
2. A button lighter than the name beside it → red.
3. You cannot say whether something is an item in a list or the subject of its block → decide that before picking a weight.
4. A toggled state that changes weight → red.
