#!/usr/bin/env node
/**
 * draft.mjs — Gemini drafts candidates for the copy of a new feature, in one paid call.
 *
 *   node draft.mjs draft  --brief <brief.md> --out <candidates.json> --langs en,zh [--n 3] [--model <openrouter id>] [--locale LOCALE.md]
 *   node draft.mjs prompt --brief <brief.md> --langs en,zh [--n 3] [--locale LOCALE.md]    # prints the prompt, calls nothing
 *
 * Run from the repo root. LOCALE.md §3–§5 (from its `## 3.` heading up to `## 6.`) go into the prompt verbatim.
 * Brief: free text on the product and the feature, then one `- \`key\` — where it shows, what it must say` line per key.
 * A `{token}` written on a key's line must appear in every language of every candidate of that key.
 * Output: { model, langs, items: [{ key, context, candidates: [{ <lang>: string }], note? }], problems: string[] }.
 * `draft` retries only a 5xx or a timeout of that same call, at most twice, and never re-prompts.
 * The key is OPENROUTER_API_KEY, from the environment or ./.env. Needs Node 20.12 or later.
 */
import { existsSync, readFileSync, realpathSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

// The strongest Gemini on OpenRouter; check https://openrouter.ai/api/v1/models for a newer flagship before each batch.
export const DEFAULT_MODEL = 'google/gemini-4-neon'
const ENDPOINT = 'https://openrouter.ai/api/v1/chat/completions'

/** Every `- \`key\` — context` line, in file order. Tokens are the `{name}` placeholders written on that line. */
export function briefKeys(md) {
  const out = []
  for (const line of md.split('\n')) {
    const m = line.match(/^\s*-\s+`([^`]+)`\s*(?:[—–-]\s*)?(.*)$/)
    if (!m) continue
    const context = m[2].trim()
    out.push({ key: m[1], context, tokens: [...new Set(context.match(/\{[a-zA-Z_]+\}/g) ?? [])] })
  }
  return out
}

/** LOCALE.md §3–§5 (tone, glossary, error messages): from the `## 3.` heading up to `## 6.`. */
export function copyRules(localeMd) {
  const start = localeMd.search(/^## 3\./m)
  const end = localeMd.search(/^## 6\./m)
  if (start < 0 || end < 0 || end <= start) throw new Error('LOCALE.md: sections 3 to 5 not found')
  return localeMd.slice(start, end).trim()
}

export function draftPrompt({ brief, rules, langs, n }) {
  const pair = Object.fromEntries(langs.map(l => [l, '…']))
  return [
    'You write the interface copy of a new feature. The brief below says what the product and the feature are.',
    `For every key listed in the brief, write ${n} candidates. Each candidate has one string per language, keyed by locale code: ${langs.join(', ')}.`,
    ...(langs.length > 1 ? ['The languages are written independently, each for its own readers, and state the same fact; none is a translation of another.'] : []),
    `The ${n} candidates of one key differ in wording or angle, not only in punctuation. Put the one you would ship first.`,
    'Keep every {token} that the key\'s line in the brief names, exactly as written, in every language.',
    'The house rules below are binding.',
    '',
    '## House rules (LOCALE.md §3–§5)',
    rules,
    '',
    '## Brief',
    brief.trim(),
    '',
    '## Output',
    'Return one JSON object and nothing else:',
    `{ "items": [ { "key": "<key>", "candidates": [ ${JSON.stringify(pair)} ], "note": "<optional: one line on a term you chose>" } ] }`,
    `Every key from the brief appears once, in the brief's order, with exactly ${n} candidates.`,
  ].join('\n')
}

/** The model's answer → its items. Tolerates a ```json fence. */
export function parseAnswer(text) {
  const t = text.trim().replace(/^```(?:json)?\s*/, '').replace(/\s*```$/, '')
  const items = JSON.parse(t).items
  if (!Array.isArray(items)) throw new Error('answer has no items array')
  return items
}

// Han and kana. Korean is left out: it uses half-width punctuation.
const CJK = '\\u3040-\\u30ff\\u3400-\\u9fff\\uf900-\\ufaff'
const HALF_WIDTH_BY_CJK = new RegExp(`[${CJK}][,.]|[,.][${CJK}]`)

/** What to know before picking: missing keys, wrong counts, empty strings, dropped tokens, half-width punctuation in CJK. */
export function problems(keys, items, langs, n) {
  const out = []
  const byKey = new Map(items.map(i => [i.key, i]))
  for (const k of keys) {
    const item = byKey.get(k.key)
    if (!item) { out.push(`${k.key}: missing`); continue }
    const cands = Array.isArray(item.candidates) ? item.candidates : []
    if (cands.length !== n) out.push(`${k.key}: ${cands.length} candidates, expected ${n}`)
    cands.forEach((c, i) => {
      const at = `${k.key} #${i + 1}`
      for (const lang of langs) {
        const s = c?.[lang]
        if (typeof s !== 'string' || !s.trim()) { out.push(`${at} ${lang}: empty`); continue }
        for (const tok of k.tokens) if (!s.includes(tok)) out.push(`${at} ${lang}: lost ${tok}`)
        if (HALF_WIDTH_BY_CJK.test(s)) out.push(`${at} ${lang}: half-width comma or period next to CJK`)
      }
    })
  }
  for (const i of items) if (!keys.some(k => k.key === i.key)) out.push(`${i.key}: not in the brief`)
  return out
}

/** Items in the brief's order, each with its context line; keys the answer skipped get no candidates. */
export function assemble(keys, answer) {
  const byKey = new Map(answer.map(i => [i.key, i]))
  return keys.map((k) => {
    const a = byKey.get(k.key)
    return { key: k.key, context: k.context, candidates: a?.candidates ?? [], ...(a?.note ? { note: a.note } : {}) }
  })
}

function arg(args, name, fallback) {
  const i = args.indexOf(name)
  const v = i >= 0 ? args[i + 1] : fallback
  if (!v) throw new Error(`${name} is required`)
  return v
}

async function callOpenRouter(model, prompt) {
  if (!process.env.OPENROUTER_API_KEY && existsSync('.env')) process.loadEnvFile('.env')
  const key = process.env.OPENROUTER_API_KEY
  if (!key) throw new Error('OPENROUTER_API_KEY is not set (environment or ./.env)')
  const body = JSON.stringify({ model, messages: [{ role: 'user', content: prompt }], usage: { include: true } })
  for (let attempt = 0; ; attempt++) {
    try {
      const res = await fetch(ENDPOINT, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${key}`, 'Content-Type': 'application/json', 'X-Title': 'ui copy draft' },
        body,
        signal: AbortSignal.timeout(20 * 60_000),
      })
      if (res.status >= 500 && attempt < 2) { console.error(`HTTP ${res.status}, retrying the same call`); continue }
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${(await res.text()).slice(0, 500)}`)
      const json = await res.json()
      const text = json.choices?.[0]?.message?.content
      if (!text) throw new Error(`no content: ${JSON.stringify(json).slice(0, 500)}`)
      return { text, usage: json.usage }
    } catch (e) {
      if (e.name === 'TimeoutError' && attempt < 2) { console.error('timeout, retrying the same call'); continue }
      throw e
    }
  }
}

function setup(args) {
  const brief = readFileSync(arg(args, '--brief'), 'utf8')
  const keys = briefKeys(brief)
  if (!keys.length) throw new Error('the brief lists no keys (expected lines like: - `app.x.y` — where it shows)')
  const langs = arg(args, '--langs').split(',').map(s => s.trim()).filter(Boolean)
  if (!langs.length) throw new Error('--langs needs at least one locale code')
  const n = Number(arg(args, '--n', '3'))
  if (!Number.isInteger(n) || n < 2 || n > 8) throw new Error('--n must be 2 to 8')
  const rules = copyRules(readFileSync(arg(args, '--locale', 'LOCALE.md'), 'utf8'))
  return { keys, langs, n, prompt: draftPrompt({ brief, rules, langs, n }) }
}

async function main() {
  const [cmd, ...args] = process.argv.slice(2)
  if (cmd === 'prompt') {
    process.stdout.write(setup(args).prompt + '\n')
    return
  }
  if (cmd === 'draft') {
    const out = arg(args, '--out')
    const { keys, langs, n, prompt } = setup(args)
    const model = arg(args, '--model', DEFAULT_MODEL)
    console.error(`model=${model} keys=${keys.length} langs=${langs.join(',')} candidates=${n} prompt_chars=${prompt.length}`)
    const { text, usage } = await callOpenRouter(model, prompt)
    const answer = parseAnswer(text)
    const file = { model, langs, items: assemble(keys, answer), problems: problems(keys, answer, langs, n) }
    writeFileSync(out, JSON.stringify(file, null, 2) + '\n')
    console.error(`usage=${JSON.stringify(usage)} problems=${file.problems.length}`)
    for (const p of file.problems) console.error(`  ${p}`)
    return
  }
  console.error('usage: draft --brief <md> --out <json> --langs <a,b> [--n 3] [--model <id>] [--locale LOCALE.md]\n       prompt --brief <md> --langs <a,b> [--n 3] [--locale LOCALE.md]')
  process.exit(2)
}

if (process.argv[1] && realpathSync(resolve(process.argv[1])) === realpathSync(fileURLToPath(import.meta.url))) {
  main().catch((e) => { console.error(e.message); process.exit(1) })
}
