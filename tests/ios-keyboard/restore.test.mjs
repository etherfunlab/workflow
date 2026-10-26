// node --test: the reference implementation shipped with the ios-keyboard-page-shift skill.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { installKeyboardScrollRestore } from '../../extras/ios-keyboard-page-shift/agent/skills/ios-keyboard-page-shift/keyboard-scroll-restore.js'

const VIEW = 800
const KEYBOARD = 340

function field(tag) {
  return { isContentEditable: false, matches: (sel) => sel.split(', ').includes(tag) }
}

function setup() {
  const vv = Object.assign(new EventTarget(), { height: VIEW, scale: 1 })
  const doc = Object.assign(new EventTarget(), { documentElement: { scrollHeight: VIEW }, activeElement: null })
  const timers = []
  const calls = []
  const win = {
    visualViewport: vv, document: doc, innerHeight: VIEW, scrollX: 0, scrollY: 0,
    scrollTo: (x, y) => calls.push([x, y]),
    setTimeout: (fn) => timers.push(fn),
  }
  installKeyboardScrollRestore(win)
  return {
    calls,
    page(docHeight, scrollY) { doc.documentElement.scrollHeight = docHeight; win.scrollY = scrollY },
    resize(height, scale = 1) { vv.height = height; vv.scale = scale; vv.dispatchEvent(new Event('resize')) },
    focusOut(next = null) { doc.activeElement = next; doc.dispatchEvent(new Event('focusout')) },
    runTimers() { timers.splice(0).forEach((fn) => fn()) },
  }
}

test('keyboard closes with the page still pushed up: clamps back into the scroll range', () => {
  const t = setup()
  t.resize(VIEW - KEYBOARD)
  t.page(VIEW, KEYBOARD)
  t.resize(VIEW)
  assert.deepEqual(t.calls, [[0, 0]])
})

test('a page that scrolls is clamped to its end, not its top', () => {
  const t = setup()
  t.page(3000, 2200)
  t.resize(VIEW - KEYBOARD)
  t.page(3000, 2200 + KEYBOARD)
  t.resize(VIEW)
  assert.deepEqual(t.calls, [[0, 3000 - VIEW]])
})

test('a small viewport gap left after the keyboard closes still counts as closed', () => {
  const t = setup()
  t.resize(VIEW - KEYBOARD)
  t.page(VIEW, KEYBOARD)
  t.resize(VIEW - 24)
  assert.deepEqual(t.calls, [[0, 0]])
})

test('nothing moves while the keyboard is up', () => {
  const t = setup()
  t.page(VIEW, KEYBOARD)
  t.resize(VIEW - KEYBOARD)
  t.resize(VIEW - KEYBOARD - 40)
  assert.deepEqual(t.calls, [])
})

test('nothing moves when the browser already clamped', () => {
  const t = setup()
  t.page(3000, 1000)
  t.resize(VIEW - KEYBOARD)
  t.resize(VIEW)
  assert.deepEqual(t.calls, [])
})

test('a viewport change without a keyboard (toolbar, overscroll at the end) is left alone', () => {
  const t = setup()
  t.page(3000, 3000 - VIEW + 60)
  t.resize(VIEW - 60)
  t.resize(VIEW)
  assert.deepEqual(t.calls, [])
})

test('pinch zoom is not a keyboard', () => {
  const t = setup()
  t.resize(VIEW / 2, 2)
  t.page(VIEW, VIEW / 2)
  t.resize(VIEW, 1)
  assert.deepEqual(t.calls, [])
})

test('focus leaves the field and the viewport never reports the close: clamps after the hide animation', () => {
  const t = setup()
  t.resize(VIEW - KEYBOARD)
  t.page(VIEW, KEYBOARD)
  t.focusOut(null)
  assert.deepEqual(t.calls, [])
  t.runTimers()
  assert.deepEqual(t.calls, [[0, 0]])
})

test('focus moving to another field leaves the page where iOS put it', () => {
  const t = setup()
  t.page(VIEW, KEYBOARD)
  t.focusOut(field('input'))
  t.runTimers()
  assert.deepEqual(t.calls, [])
})
