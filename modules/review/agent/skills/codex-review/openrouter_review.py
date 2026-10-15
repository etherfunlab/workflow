#!/usr/bin/env python3
"""One-shot code review through OpenRouter: the fallback when codex is out of quota.

Takes the same hand-written, diff-inlined prompt that would have gone to `codex exec`
and sends it as a single chat completion. Writes the review to --out; prints model and
token usage to stderr. Reads OPENROUTER_API_KEY from the environment and never prints it.

Pay-per-call: one run per review. Retries only transient failures (HTTP 5xx, timeout)
of this same call, at most twice; never re-prompts on its own.

Usage:
  set -a && . <your env file> && set +a && \
    python3 openrouter_review.py --prompt prompt.txt --out review.md [--model openai/<model>]
"""
import argparse
import json
import os
import socket
import sys
import time
import urllib.error
import urllib.request

DEFAULT_MODEL = "openai/gpt-6-astra-pro"
ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
MAX_TRANSIENT_RETRIES = 2

def redact(text: str, key: str) -> str:
    """Remove the API key from text that may echo request headers."""
    return text.replace(key, "[redacted]") if key else text


SYSTEM = """You are a staff engineer doing a pre-merge review of a feature branch in a live product with real users. Your value is finding real defects, not restating the diff.

Bias hard toward correctness bugs, wrong assumptions about systems outside the diff, concurrency and money-safety holes, and tests that pass for the wrong reason. Skip style, naming and formatting entirely.

Report only findings you can defend with a concrete failure scenario: specific inputs or interleavings, and the wrong output or state that results. If you cannot name the scenario, do not report the item. If you find nothing, say so plainly."""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", required=True, help="file with the full review prompt (diff inlined)")
    ap.add_argument("--out", required=True, help="where to write the review text")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    args = ap.parse_args()

    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        sys.exit("OPENROUTER_API_KEY not set (source your env file first)")

    with open(args.prompt, encoding="utf-8") as f:
        prompt = f.read()
    body = json.dumps({
        "model": args.model,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt},
        ],
    }).encode()
    req = urllib.request.Request(
        ENDPOINT,
        data=body,
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            "X-Title": "codex-review fallback",
        },
    )

    print(f"model={args.model} prompt_chars={len(prompt)}", file=sys.stderr)
    out = None
    for attempt in range(MAX_TRANSIENT_RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=1800) as r:
                out = json.load(r)
            break
        except urllib.error.HTTPError as e:
            if e.code >= 500 and attempt < MAX_TRANSIENT_RETRIES:
                print(f"HTTP {e.code}, retrying the same call ({attempt + 1}/{MAX_TRANSIENT_RETRIES})", file=sys.stderr)
                time.sleep(10)
                continue
            sys.exit(redact(f"HTTP {e.code}: {e.read().decode(errors='replace')[:500]}", key))
        except (socket.timeout, TimeoutError, urllib.error.URLError) as e:
            if attempt < MAX_TRANSIENT_RETRIES:
                print(f"{type(e).__name__}, retrying the same call ({attempt + 1}/{MAX_TRANSIENT_RETRIES})", file=sys.stderr)
                time.sleep(10)
                continue
            sys.exit(redact(f"request failed: {e}", key))

    if not out or "choices" not in out:
        sys.exit(redact(f"no choices in response: {json.dumps(out)[:500]}", key))
    text = out["choices"][0]["message"].get("content") or ""
    if not text.strip():
        sys.exit("empty review content")
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(text)
    u = out.get("usage", {})
    print(f"usage: prompt={u.get('prompt_tokens')} completion={u.get('completion_tokens')} cost={u.get('cost')}", file=sys.stderr)


if __name__ == "__main__":
    main()
