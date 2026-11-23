import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { assemble, briefKeys, copyRules, draftPrompt, parseAnswer, problems } from '../../modules/publish/agent/skills/ui-copy-gemini/draft.mjs'

const root = resolve(import.meta.dirname, '../..')
const script = join(root, 'modules/publish/agent/skills/ui-copy-gemini/draft.mjs')
const templateLocale = readFileSync(join(root, 'templates/frontend/LOCALE.md'), 'utf8')

const BRIEF = [
  '# Shared albums',
  '',
  'A photo app. The reader is a signed-in user on the album page.',
  '- not a key line',
  '',
  '## Keys',
  '- `app.album.share.title` — heading of the share dialog',
  '- `app.album.share.limit` — one line when the album is full, with {cap} (the member limit)',
  '- `app.album.share.copy` - the primary button, {cap} again {cap}',
].join('\n')

test('briefKeys reads key lines in order, with their tokens', () => {
  const keys = briefKeys(BRIEF)
  assert.deepEqual(keys.map(k => k.key), ['app.album.share.title', 'app.album.share.limit', 'app.album.share.copy'])
  assert.deepEqual(keys[0].tokens, [])
  assert.deepEqual(keys[1].tokens, ['{cap}'])
  assert.deepEqual(keys[2].tokens, ['{cap}'])
  assert.equal(keys[0].context, 'heading of the share dialog')
})

test('copyRules takes sections 3 to 5 of the frontend template LOCALE.md', () => {
  const rules = copyRules(templateLocale)
  assert.match(rules, /^## 3\. Tone/)
  assert.match(rules, /^## 5\. Error messages/m)
  assert.doesNotMatch(rules, /^## (?:[0-2]|[6-9])\./m)
})

test('copyRules fails loudly on a LOCALE.md without those sections', () => {
  assert.throws(() => copyRules('# LOCALE\n## 1. Locales\n'), /sections 3 to 5 not found/)
})

test('draftPrompt carries the languages, the count, the rules and the brief', () => {
  const p = draftPrompt({ brief: BRIEF, rules: 'RULES-HERE', langs: ['en', 'zh'], n: 3 })
  assert.match(p, /keyed by locale code: en, zh/)
  assert.match(p, /written independently/)
  assert.match(p, /exactly 3 candidates/)
  assert.match(p, /RULES-HERE/)
  assert.match(p, /app\.album\.share\.limit/)
  assert.match(p, /"en":"…","zh":"…"/)
  const one = draftPrompt({ brief: BRIEF, rules: 'R', langs: ['en'], n: 2 })
  assert.doesNotMatch(one, /written independently/)
})

test('parseAnswer tolerates a json fence and rejects an answer without items', () => {
  assert.deepEqual(parseAnswer('```json\n{"items":[{"key":"a","candidates":[]}]}\n```'), [{ key: 'a', candidates: [] }])
  assert.throws(() => parseAnswer('{"nope":1}'), /no items array/)
})

test('problems is empty for a clean answer', () => {
  const keys = briefKeys('- `a.b` — with {n}\n')
  const items = [{ key: 'a.b', candidates: [{ en: 'Up to {n}', zh: '最多 {n} 人，已满。' }, { en: 'Limit {n}', zh: '上限 {n}' }] }]
  assert.deepEqual(problems(keys, items, ['en', 'zh'], 2), [])
})

test('problems names every kind of defect', () => {
  const keys = briefKeys('- `a.b` — with {n}\n- `a.c` — plain\n')
  const items = [
    { key: 'a.b', candidates: [{ en: 'No token', zh: '' }, { en: 'Has {n}', zh: '已满,请稍后 {n}' }, { en: 'Has {n}', zh: '满了.{n}' }] },
    { key: 'x.y', candidates: [] },
  ]
  const p = problems(keys, items, ['en', 'zh'], 2)
  assert.ok(p.includes('a.b: 3 candidates, expected 2'))
  assert.ok(p.includes('a.b #1 en: lost {n}'))
  assert.ok(p.includes('a.b #1 zh: empty'))
  assert.ok(p.includes('a.b #2 zh: half-width comma or period next to CJK'))
  assert.ok(p.includes('a.b #3 zh: half-width comma or period next to CJK'))
  assert.ok(p.includes('a.c: missing'))
  assert.ok(p.includes('x.y: not in the brief'))
})

test('problems leaves Korean and Latin punctuation alone', () => {
  const keys = briefKeys('- `a.b` — plain\n')
  const items = [{ key: 'a.b', candidates: [{ ko: '앨범이 가득 찼습니다. 나중에 다시 시도하세요.', en: 'Full, try later.' }, { ko: '가득 참', en: 'Full' }] }]
  assert.deepEqual(problems(keys, items, ['ko', 'en'], 2), [])
})

test('assemble keeps the brief order and the context', () => {
  const keys = briefKeys(BRIEF)
  const out = assemble(keys, [{ key: 'app.album.share.copy', candidates: [{ en: 'x' }], note: 'n' }])
  assert.deepEqual(out.map(i => i.key), keys.map(k => k.key))
  assert.deepEqual(out[0].candidates, [])
  assert.equal(out[2].note, 'n')
  assert.equal(out[1].context, keys[1].context)
})

function run(args, cwd) {
  const env = { ...process.env }
  delete env.OPENROUTER_API_KEY
  return spawnSync(process.execPath, [script, ...args], { cwd, env, encoding: 'utf8' })
}

function workdir() {
  const d = mkdtempSync(join(tmpdir(), 'ui-copy-'))
  writeFileSync(join(d, 'LOCALE.md'), templateLocale)
  writeFileSync(join(d, 'brief.md'), BRIEF)
  return d
}

test('prompt prints the prompt from LOCALE.md in the working directory', () => {
  const r = run(['prompt', '--brief', 'brief.md', '--langs', 'en,zh'], workdir())
  assert.equal(r.status, 0, r.stderr)
  assert.match(r.stdout, /## House rules \(LOCALE\.md §3–§5\)\n## 3\. Tone/)
  assert.match(r.stdout, /app\.album\.share\.copy/)
})

test('missing --langs and a bad --n are refused', () => {
  const d = workdir()
  assert.match(run(['prompt', '--brief', 'brief.md'], d).stderr, /--langs is required/)
  assert.match(run(['prompt', '--brief', 'brief.md', '--langs', 'en', '--n', '9'], d).stderr, /--n must be 2 to 8/)
})

test('draft stops before any call when no key is set', () => {
  const r = run(['draft', '--brief', 'brief.md', '--out', 'c.json', '--langs', 'en,zh'], workdir())
  assert.equal(r.status, 1)
  assert.match(r.stderr, /OPENROUTER_API_KEY is not set/)
})

test('draft needs --out before anything else', () => {
  const r = run(['draft', '--brief', 'brief.md', '--langs', 'en'], workdir())
  assert.equal(r.status, 1)
  assert.match(r.stderr, /--out is required/)
})

test('no subcommand prints usage', () => {
  assert.equal(run([], workdir()).status, 2)
})
