// Puts the document back inside its scroll range after the iOS soft keyboard closes.
//
// To show a focused field above the keyboard, iOS scrolls the document past its end. When the
// keyboard closes it should clamp that offset back; from iOS 26 it sometimes leaves it, and the
// page stays pushed up with the bare canvas showing below it. This clamps scrollY into
// [0, scrollHeight - innerHeight] once the keyboard is down. It never moves a position the
// browser left in range, so pages that scroll as the document keep their place.
//
// Install once per page load, client side only:
//   import { installKeyboardScrollRestore } from './keyboard-scroll-restore.js'
//   installKeyboardScrollRestore()

// Shorter than any soft keyboard, taller than a toolbar resize and the viewport gap iOS 26 can
// leave behind after the keyboard closes.
const KEYBOARD_MIN_PX = 150
// Past the keyboard's hide animation; clamping mid-animation gets undone.
const KEYBOARD_HIDE_MS = 400

export function installKeyboardScrollRestore(win = window) {
  const vv = win.visualViewport
  if (!vv) return () => {}
  const doc = win.document

  function clamp() {
    const max = Math.max(0, doc.documentElement.scrollHeight - win.innerHeight)
    if (win.scrollY > max) win.scrollTo(win.scrollX, max)
  }

  function isEditable(el) {
    return !!el && (el.isContentEditable || el.matches('input, textarea, select'))
  }

  // Trigger 1: the visual viewport grows back from keyboard height. Catches a keyboard closed
  // while focus stays on the field. Zoom is factored out so pinch zoom is not a keyboard.
  let keyboardUp = false
  function onResize() {
    const up = win.innerHeight - vv.height * vv.scale >= KEYBOARD_MIN_PX
    const closed = keyboardUp && !up
    keyboardUp = up
    if (closed) clamp()
  }

  // Trigger 2: focus left every editable element (Done, a send button that blurs). Catches iOS
  // never reporting the viewport growing back, or reporting it before it settles its own scroll.
  // Focus moving to another field keeps the keyboard up, so nothing happens.
  function onFocusOut() {
    win.setTimeout(() => {
      if (!isEditable(doc.activeElement)) clamp()
    }, KEYBOARD_HIDE_MS)
  }

  vv.addEventListener('resize', onResize)
  doc.addEventListener('focusout', onFocusOut)
  return () => {
    vv.removeEventListener('resize', onResize)
    doc.removeEventListener('focusout', onFocusOut)
  }
}
