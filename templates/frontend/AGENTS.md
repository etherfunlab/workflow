# AGENTS.md

## Read in this order

| # | Read | For |
|---|---|---|
| 2 | `DESIGN.md` | Visual constitution: surfaces, tokens, breakpoints, alignment, spacing. Before any style change |
| 3 | `FONTS.md` | Families, weight tiers, sizes. Before changing any of them |
| 4 | `GRID.md` | Container and columns of the public pages. Before changing their layout |
| 5 | `LOCALE.md` | All user-visible copy and the i18n workflow. Before changing copy |
| 6 | `RELEASE.md` | Release notes and version numbers. Before writing a note or changing a version |
| 7 | `WRITER.md` | Who drafts each kind of copy and how to call them. Before writing any user-visible text |

## Frontend

Stack: Vue 3.5 or later and Tailwind CSS 4. TODO: the i18n library, and the commands for dev, test, typecheck, build and end-to-end tests.

### The spec files

- The six files above sit side by side at the repo root, and none repeats another. Token values live only in TODO: the tokens file; the spec files hold the rules.
- Tailwind is configured in CSS: the tokens file declares the tokens with `@theme`, and there is no `tailwind.config.js`.
- Section numbers are anchors, not order. Code comments and other files cite `DESIGN.md §N`; a number is never changed or reused, and a new section takes the next free number.
- A part or section that overrides another names the one it overrides.

### Building

- Import from the subpath you use, not from a third-party package's barrel entry. Whether a barrel tree-shakes depends on the package (side-effect flags, how it re-exports) and on how you use it; when it does not, the whole barrel ships, including dependencies that may break only in the production build. After upgrading the framework or a dependency, run a real production build and load TODO: the key pages.
- Decide whether you are in production by the runtime hostname, not by build-time environment variables: a preview deployment can be promoted to the production domain with the old values baked in.

### Verifying

- A headless browser asserts behavior and flows. It never takes screenshots to judge looks. Widths, alignment, spacing and breakpoints are worked out from the CSS.
- Looks, layout, art and the tone of copy are judged by a person. Show about three candidates side by side and stop until one is picked; the final version goes back for a yes before it lands in code. Before/after of any mechanical change to art (crop, scale, recolor, re-encode) goes to a person before you continue.
- To tell whether a change broke end-to-end tests that already have failures, run the same specs on the base and on the branch and compare the sets of failing test names, never their counts. Equal counts can hide a new failure behind a flaky test that happened to pass.
- Guard tests that scan the source (raw colors, banned weights, copy gates) have unit tests with samples that try to get past them. A guard that is green only because the repo happens to be clean guards nothing.

## Directory map

| Path | What |
|---|---|
| `DESIGN.md`, `FONTS.md`, `GRID.md`, `LOCALE.md`, `RELEASE.md`, `WRITER.md` | Frontend specs |
| TODO: tokens file | Token values: colors, shadows, radii, weights, font stacks |
| TODO: locale files | Copy, one set per locale |
