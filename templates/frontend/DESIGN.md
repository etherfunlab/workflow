# DESIGN.md — visual constitution

> The highest authority on how this product looks. Read it before changing any style; review ticks §0 and uses §3 as its criteria.
> Families, weights and sizes are in `FONTS.md`; the grid of public pages is in `GRID.md`.
> Token values live only in TODO: the tokens file (for example `src/styles/tokens.css`). This file says what each token is for and repeats no values.
>
> Part A holds what more than one surface uses. Each surface gets its own part with only what is specific to it. A part that overrides a section of part A names that section; anything it does not name follows part A.
>
> - **A · Constitution**: every surface.
> - **B · TODO: surface** (for example the signed-in app): TODO: routes.
> - **C · TODO: surface** (for example the admin console): TODO: routes.
> - **D · TODO: surface** (for example the landing page): TODO: routes.

---

# A · Constitution

## 0. Quick checklist (tick each in review)

1. Every color, shadow and radius at a call site is a token name; no raw palette classes, no hex (§4, machine gate).
2. Hierarchy comes from surface levels (§2), not from borders.
3. Brand colors go into fills, icons and text emphasis. Status colors (§4) mean status and nothing else.
4. Text passes 4.5:1 and non-text marks 3:1 against their real background, in every theme (§4).
5. Only the breakpoints in §5; every changed page passes the §8 matrix.
6. `backdrop-filter` only on a surface that content scrolls under (§2).
7. Things meant to sit on one row share one box; left edges align on the ink, not the box (§6).
8. Ambient motion stops under `prefers-reduced-motion` (§7).
9. TODO: product checks, one line each.

## 1. World

TODO: one paragraph on what the product looks and feels like in each theme, with two or three reference products, and what it is not.

A dark theme is the same world at another time of day, not the light theme with its colors inverted. Every token has a value per theme; brand colors may keep one value across themes.

## 2. Surfaces

Hierarchy is carried by a capped set of surface levels and neutral shadows, not by borders.

| Level | Name | Who gets it | Class |
|---|---|---|---|
| L0 | ground | the page background | TODO |
| L1 | panel | sidebars, fixed toolbars | TODO |
| L2 | card | real objects: TODO (for example product cards, message bubbles, the composer) | TODO |
| L3 | overlay | modals, sheets, popovers, menus | TODO |

- No level above L3. An overlay is always one level above what it covers.
- List rows are not cards. Conversation rows, settings rows and navigation rows are bare by default and take a surface only on hover or when active.
- Blur (`backdrop-filter`) belongs on a surface that content passes under. On a surface nothing scrolls beneath, it costs GPU and shows nothing; use a solid fill.

## 3. Anti-patterns (review criteria)

| Feels | Cause | NEVER | INSTEAD |
|---|---|---|---|
| Engineered | Every surface the same value, split by borders | Borders to express hierarchy; adjacent surfaces of equal value | Surface levels and neutral shadows (§2) |
| Generic | Everything an equally rounded outlined box; no display hierarchy | List rows as separate outlined cards | Bare rows that take a surface on hover (§2) |
| Wasted GPU | Blur on a surface nothing passes under | Blur as decoration | A solid fill (§2) |
| TODO | | | |

## 4. Token contract

Values live only in the tokens file, one block per theme. A new token goes into this table and the tokens file in the same change.

| Group | Tokens | For |
|---|---|---|
| Brand | TODO: primary / secondary / accent | Fills, icons, text emphasis; never the ground, never shadows |
| On-brand | TODO | Ink on solid brand fills |
| Ground | TODO | L0, per theme |
| Ink | TODO: ink / ink-muted | Text; one muted level only |
| Surfaces | TODO | L1–L3 (§2) |
| Shadows | TODO | Neutral; no colored glow |
| Success | `success` / `success-ink` / `success-tint` / `success-line` | Solid fill / text and icons on any surface / badge and soft-button background / outline |
| Danger | `danger` / `danger-ink` / `danger-tint` / `danger-line` | Same roles: errors, deletes, over-limit counts |
| TODO: other status colors | | |

- Status colors are not brand colors, even when a brand color is close to one.
- Text and icons in a status color come only from its `*-ink` token, which changes per theme so it stays readable on both grounds. White text and icons sit only on the solid fill.
- A dot or mark that is the only carrier of a state (its label is screen-reader only) uses the solid fill; a light tint fails 3:1 on a light ground.
- Solid destructive buttons darken on hover. A transparency hover blends toward the ground and the white label loses contrast.
- Call sites write token names. Raw palette classes (`red-500`, `emerald-*`) and hex values at call sites are red; a guard test scans for them.

## 5. Breakpoints

- TODO: the zones and their prefixes (for example phone, `sm:` 640–1023, `lg:` ≥1024). No other breakpoint prefix appears in code.
- TODO: whether phone and desktop are designed separately or phone-first and stretched; whether tablets get their own layout.

## 6. Alignment

Applies to anything that stacks rows on one surface: cards, overlay headers, list rows.

### 6.1 Things on one row share one box

Elements that belong on the same line (name and badge, price and button, overlay title and close button, row name and timestamp) go into one flex row that aligns them.

- Never put one in the flow and pin the other to a corner with `absolute top-N right-N`. The row's center line follows font size and line height; the corner constant does not, and the flow element then needs a `pr-N` to avoid overlap, a third constant to maintain.
- Truncation is computed by flex, not by padding: the element that grows gets `min-w-0 flex-1 truncate`, the fixed one `shrink-0`.
- Elements in different boxes are never nudged onto one center line with offsets. To share a line they share a box.
- A row-end button belongs to its row. As a sibling of the whole text column it takes the card's full height and narrows every row above it.
- A row that stands alone gets equal space above and below, from one gap value.
- Exception: overlays on an image (close button on a photo, corner badge) align to the image edge, so `absolute` is right.

### 6.2 Left edges align on the ink

Readers see glyphs, not boxes. A pill with a background has its text one horizontal padding inside its box edge, so box-aligned pills read as indented. Pick one fix per surface: let the pill row bleed into the gutter by its padding (all pills in the column then need the same padding), or indent the bare text in the column by the same padding.

### 6.3 Mixed sizes align on the visual center

When two font sizes share a line, baseline alignment makes the smaller text look low. Align them with `inline-flex` and `align-items: center`; `text-box: trim-both text` closes the last pixel. Use the `text` edge, not `cap alphabetic`, which clips CJK glyphs. Never fix it with `top: -1px`: the offset depends on font metrics and breaks with the next size or locale. Never enlarge the small text to align it; the size difference is hierarchy (`FONTS.md` §2).

### 6.4 Review criteria

1. A corner element is `absolute` while a flow element beside it should share its line → red.
2. A flow element carries `pr-N` / `pe-N` to make room for a corner element → red.
3. Two boxes are offset with `h-N` + `pb-N` / `mb-N` to meet one center line → red.
4. Pill and bare-text columns align on the box but not the ink → red.
5. Paired text on one row differs in size or line height → red.
6. A row that stands alone has unequal space above and below → red.

## 7. Motion

- TODO: durations and easing tokens.
- Under `prefers-reduced-motion`, ambient motion stops and transitions shorten.
- A state that toggles (selected, current page) never changes width; see `FONTS.md` §2.

## 8. Verification matrix

A changed page is done when it passes every cell of TODO: the zones from §5 × the themes. Also check:

- TODO: mobile browser chrome (status bar and URL bar colors) on the target devices;
- ambient motion stops under reduced motion.

## 9. Spacing

- One unit: TODO (for example 12px). Spacing inside a row of controls starts at one unit; tighter, half a unit, only between two marks of the same thing. Hierarchy comes from size and color, not from wider gaps.
- The items at the two ends of a bar have equal visual space on each side: the screen margin equals the gap to the neighbor.
- Measure from the visible edge. A ring or glow around an avatar is part of it, so the gap starts outside the ring.
- Touch targets are fixed in the hit area (at least 44px on phones, extended with `::before` when needed), not by enlarging the visual.

---

# B · TODO: surface

TODO: only what is specific to this surface. Name every section of part A this part overrides.

# C · TODO: surface

TODO

# D · TODO: surface

TODO
