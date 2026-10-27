# ios-keyboard-page-shift

For teams building mobile web pages.

## What it is

A skill for the iPhone bug where the page does not come back down after the keyboard closes: the top bar is off-screen, the input sits mid-screen, and an empty band shows below it. It ships a reference implementation that clamps the document's scroll position back into range once the keyboard has closed.

## Why

Two causes produce the same screenshot. To show a focused field above the keyboard, iOS scrolls every scrollable ancestor of the field and the document itself, and whichever layer is left displaced looks the same. A fix on the wrong layer leaves the bug in place, so the skill's first step tells the layers apart: does the band below the input show the app's own background, or the bare `html` / `body` color?

The two layers need different fixes. The inner layer is structural: make the list that is meant to scroll the containing block of its absolutely positioned descendants, and give shell layers `overflow: clip`. The document layer is browser behaviour from iOS 26 on and can only be corrected by a script after the keyboard closes. Every condition in that script is load-bearing; for example, "keyboard closed" cannot mean "viewport height equals window height", because iOS 26 can leave the viewport about twenty pixels short.

## How to use it

Agents load it from its description when the symptom shows up on an iPhone, or say "the page doesn't come back down after the iOS keyboard closes". The reference implementation `keyboard-scroll-restore.js` has no framework dependency: call `installKeyboardScrollRestore()` once per page load, client side.

## What gets installed

Skill `ios-keyboard-page-shift`, with `keyboard-scroll-restore.js`, in the skills directory you chose. No placeholders.

## Dependencies

None. Only a real iPhone can verify it: desktop Safari and Playwright WebKit have no soft keyboard.
