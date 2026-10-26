# GRID.md — grid of the public pages

> This file governs only the grid of the public pages: container, columns, reading-page layout. Ground, surfaces, tokens and alignment follow `DESIGN.md`; type follows `FONTS.md`. App pages are laid out by `DESIGN.md`, not by this file.

## 0. Scope

- Public pages: TODO: routes (for example `/`, `/legal/*`, `/updates/*`), including the same paths under each locale prefix.
- Not covered: TODO: routes laid out by `DESIGN.md` (the signed-in app, admin, sign-in, onboarding).

## 1. Container

- TODO: one container class (for example `max-w-6xl mx-auto` plus a horizontal padding that also clears the safe area).
- The header's desktop row, the page body and the footer use the same container, so their left and right edges line up.

## 2. Columns

- TODO: from which breakpoint the page has columns, how many, and the gap (for example 12 columns with a 24px gap from `lg:`).
- Below that breakpoint, one column. TODO: whether the middle zone gets its own layout.
- Only the breakpoints in `DESIGN.md` §5.

## 3. Reading pages

For long-form pages: TODO: routes (legal documents, changelog, articles).

| Area | Wide | Narrow |
|---|---|---|
| Side note (date, document type, version, effective date) | TODO: columns; sticks while scrolling | One line above the title |
| Title (h1), one line | TODO: columns | First line |
| Body | TODO: columns | Full width, at most TODO (for example 40rem) |
| Table of contents | TODO: columns; sticks while scrolling | Hidden |

- Keep the body measure readable (TODO: maximum width); the body column is never wider than that.
- Sticky elements clear the sticky header: when the header sticks at `top-0`, a sticky sidebar starts below its height, not at `top-0`.
- The page header is the title line only; no subtitle, count or description line under it.
- Entries and sections are separated by space or a hairline, not by cards.

## 4. Landing

- Every section of the landing page uses the container from §1.
- TODO: anything this file fixes about the landing layout, or a pointer to the `DESIGN.md` part that owns it.

## 5. Review criteria

1. A public page's content container is not the §1 container → red.
2. On a reading page, the body sits outside its columns or is wider than its measure → red.
3. A breakpoint prefix outside `DESIGN.md` §5 → red.
4. A reading page header has a second line (subtitle, count, description) → red.
