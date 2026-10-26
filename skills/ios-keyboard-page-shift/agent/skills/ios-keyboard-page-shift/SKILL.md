---
name: ios-keyboard-page-shift
description: Use when, on iPhone Safari or an iOS WebView, a page or a full-screen app shell (top bar, scrolling list, bottom input) moves up when a text field is focused and stays up after the keyboard closes, leaving the top bar off-screen, the input mid-screen and an empty band below it, or when an earlier fix for that symptom did not hold.
---

# iOS keyboard page shift

## Overview

To show a focused field above the soft keyboard, iOS scrolls two kinds of things: every ancestor of the field that is a scroll container with room to scroll, and the document itself. Either one can be left displaced after the keyboard closes, and both give the same screenshot. Find which layer moved before fixing anything; a fix on the other layer changes nothing.

## Step 1: find the layer

Look at what fills the band below the input.

| Band below the input | Layer that moved | Fix |
|---|---|---|
| The app's own background, continuous with the rest of the screen | an inner scroll container | A |
| The bare `html`/`body` color, with a hard edge where the app's background ends | the document | B |

Confirm on the device: Safari on a Mac → Develop → the iPhone, focus the field, close the keyboard, then run:

```js
for (let el = document.activeElement; el; el = el.parentElement) {
  const oy = getComputedStyle(el).overflowY
  if (oy !== 'visible' && oy !== 'clip' && el.scrollHeight > el.clientHeight) console.log(el, oy, el.scrollTop)
}
console.log('document', scrollY, visualViewport.offsetTop, visualViewport.height, innerHeight, document.documentElement.scrollHeight)
```

Any listed element other than the list that is meant to scroll, or with a non-zero `scrollTop`, means Fix A. `scrollY` above `scrollHeight - innerHeight` means Fix B. Both can be true; do A, then B.

## Fix A: no outer layer can scroll

An ancestor of the field is a scroll container (`overflow` `auto`, `scroll` or `hidden`; `hidden` still scrolls for scripts and for iOS) and has scrollable overflow. The usual source is an absolutely positioned descendant (an `sr-only` label, a badge, a tooltip) whose containing block lies outside the element meant to scroll. It neither scrolls nor clips with that element, stays at its unscrolled position as far down as the list is long, and adds to the overflow of the next scroll container up.

1. Make the element meant to scroll the containing block: `position: relative` on it.
2. Give shell layers that must never scroll `overflow: clip`. It clips like `hidden` but is not a scroll container, so nothing can park it off-axis.

Find escaped elements with `list` set to the element meant to scroll:

```js
for (const el of list.querySelectorAll('*'))
  if (getComputedStyle(el).position === 'absolute' && !list.contains(el.offsetParent)) console.log(el, el.offsetParent)
```

## Fix B: clamp the document after the keyboard closes

iOS should clamp the document back into range when the keyboard closes. From iOS 26 it sometimes does not; WKWebView on iOS 11 to 13.3 had the same bug. Install `keyboard-scroll-restore.js` (next to this file) once per page load, client side only. It clamps `scrollY` into `[0, scrollHeight - innerHeight]` when either:

- the visual viewport goes from at least 150 px shorter than `innerHeight` (zoom factored out) back to full: a keyboard closed while focus stayed on the field;
- 400 ms after a `focusout` that leaves no input, textarea, select or contenteditable focused: Done, or a send button that blurs. This covers iOS never reporting the viewport growing back, or reporting it before it settles its own scroll.

Each condition is load-bearing:

| Condition | Without it |
|---|---|
| clamp to the range, not to 0 | pages that scroll as the document jump to the top |
| keyboard counted as closed within 150 px of `innerHeight` | iOS 26 can leave the viewport ~24 px short, so an exact-equality check never fires |
| act only once the keyboard is down | the field gets pulled under the keyboard |
| wait out the hide animation | iOS undoes a clamp made mid-animation |
| skip when focus moved to another field | the page jumps while the user moves between fields |

## Verify

Only a real iPhone shows this; desktop Safari and Playwright WebKit have no soft keyboard. Close the keyboard with Done and with the send button, move focus between two fields, and on a long page scrolled halfway close the keyboard from a field (the position must stay). If the fix does not hold, log the `document` line from Step 1 on the device before changing anything.

## Common mistakes

| Mistake | What happens |
|---|---|
| Painting the app background on `html` | The band looks right; the page is still shifted |
| `position: fixed` on `body` or the root | Breaks pages that scroll as the document; iOS still pans the visual viewport |
| Resizing the shell to `visualViewport.height` on every resize | Jitters as Safari's toolbar collapses |
| Fixing layer A when the band is the bare canvas | Nothing changes |
