#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# EVERY MODEL REPLY IS A NEW DRAW. They come from llama3.2:3b, through assist
# (lesson 3 shows it whole) or through the Anthropic SDK, with no temperature
# set, so a rerun gets different replies, and the lesson discusses the ones it
# shows. The loop in iterate asks again with the latest failure until the suite
# passes, three times at most, and the lesson shows every try. What is
# repeatable: git apply's verdict on a given diff, swap, and every test ana
# wrote.
#
#   model    llama3.2:3b (a80c4f17acd5), Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, and the files ana wrote (put below), each of which a lesson
# shows whole; put refuses one that no lesson shows byte for byte.
#
# pytest ends with how long its run took, "8 passed in 0.72s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab reset
put scratch/assist.py <<'PY'
"""assist: an editor assistant small enough to read, written for this course.

The assistants built into editors do three things before a model sees anything:
they decide which text to send (the file around the cursor, other files that look
related, the project's instruction file), they leave out what they were told to
leave out, and they fit the rest into a token budget. This does the same three
things against your local models, prints what it sent, and keeps the whole
request in scratch/sent.json and the reply in scratch/reply.txt, which the real
ones do not show you. It is not a
copy of any of them: their exact rules are their own and mostly unpublished.

    python scratch/assist.py complete FILE:LINE [--open FILE ...] [--accept]
    python scratch/assist.py ask "QUESTION" [--open FILE ...] [--write FILE]

Completion uses a small code model trained to fill a gap between the text before
the cursor and the text after it; questions go to the chat model. Rules:
AGENTS.md, if present, goes first. Paths matching a line of .assistignore are
never read. A file holding something shaped like a secret is refused rather than
sent. The budget is 3,000 tokens of context. --accept puts the suggestion into
the file at the cursor, as pressing Tab would; --write puts the first block of
code in the reply into FILE, as a chat panel's Apply button would.
"""
import argparse
import fnmatch
import json
import os
import re
import sys
import urllib.request

import anthropic
import tiktoken

ENC = tiktoken.get_encoding("o200k_base")
BUDGET = 3000
SECRET = re.compile(r"(?i)(token|secret|password|api_key)\s*[=:]\s*\S{8,}")
CHAT, CODE = "llama3.2:3b", "qwen2.5-coder:1.5b"


def ignored(path):
    try:
        patterns = [p.strip() for p in open(".assistignore") if p.strip() and not p.startswith("#")]
    except FileNotFoundError:
        return False
    return any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(os.path.basename(path), p) for p in patterns)


def gather(paths, used):
    """The other files, in order, each whole or not at all, within what is left of the budget."""
    parts, notes = [], []
    for p in paths:
        if ignored(p):
            notes.append(f"skipped {p}: listed in .assistignore")
            continue
        text = open(p).read()
        if SECRET.search(text):
            notes.append(f"refused {p}: it holds something shaped like a secret")
            continue
        n = len(ENC.encode(text))
        if used + n > BUDGET:
            notes.append(f"dropped {p}: {n} tokens would pass the budget")
            continue
        parts.append((p, text, n))
        used += n
    return parts, used, notes


def as_comment(name, text):
    """Another file, for a code model: commented out, so it reads as context and not as code."""
    return "".join(f"# {line}\n".replace("# \n", "#\n") for line in [f"Path: {name}"] + text.split("\n"))


def report(sections, used, notes):
    print(f"context sent ({used} of {BUDGET} tokens):", file=sys.stderr)
    for name, _, n in sections:
        print(f"  {n:5}  {name}", file=sys.stderr)
    for note in notes:
        print(f"  {note}", file=sys.stderr)
    print("---", file=sys.stderr)


def complete(target, opened, accept):
    path, line = target.rsplit(":", 1)
    lines = open(path).read().split("\n")
    k = int(line)
    before, after = "\n".join(lines[:k - 1]) + "\n", "\n" + "\n".join(lines[k:])
    sections, used = [], 0
    if os.path.exists("AGENTS.md"):
        text = open("AGENTS.md").read()
        sections.append(("AGENTS.md", text, len(ENC.encode(text))))
        used += sections[-1][2]
    n = len(ENC.encode(before + after))
    sections.append((f"{path} (cursor at line {line})", None, n))
    used += n
    others, used, notes = gather(opened, used)
    sections += others
    report(sections, used, notes)
    context = "".join(as_comment(name, text) for name, text, _ in sections if text is not None)
    # Stop at the first blank line, so that one suggestion is one block.
    request = {"model": CODE, "prompt": context + before, "suffix": after, "stream": False,
               "options": {"num_predict": 300, "stop": ["\n\n"]}}
    json.dump(request, open("scratch/sent.json", "w"), indent=1)
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(request).encode())
    suggestion = json.load(urllib.request.urlopen(req))["response"].rstrip("\n")
    open("scratch/reply.txt", "w").write(suggestion + "\n")
    print(suggestion)
    if accept:
        lines[k - 1:k] = suggestion.split("\n")
        open(path, "w").write("\n".join(lines))


def ask(question, opened, write):
    sections, used = [], 0
    if os.path.exists("AGENTS.md"):
        text = open("AGENTS.md").read()
        sections.append(("AGENTS.md", text, len(ENC.encode(text))))
        used += sections[-1][2]
    others, used, notes = gather(opened, used)
    sections += others
    report(sections, used, notes)
    prompt = "".join(f"### {name}\n{text}\n" for name, text, _ in sections) + "\n" + question
    request = {"model": CHAT, "max_tokens": 1500,
               "system": "You answer questions about the files shown, briefly, as a senior colleague would.",
               "messages": [{"role": "user", "content": prompt}]}
    json.dump(request, open("scratch/sent.json", "w"), indent=1)
    reply = anthropic.Anthropic().messages.create(**request).content[0].text
    open("scratch/reply.txt", "w").write(reply + "\n")
    print(reply)
    if write:
        block = re.search(r"```\w*\n(.*?)\n```", reply, re.S)
        if not block:
            sys.exit("assist: the reply has no block of code to write")
        open(write, "w").write(block.group(1) + "\n")


def main():
    ap = argparse.ArgumentParser(prog="assist")
    ap.add_argument("mode", choices=["complete", "ask"])
    ap.add_argument("target")
    ap.add_argument("--open", nargs="*", default=[], help="other files open in the editor")
    ap.add_argument("--accept", action="store_true", help="insert the completion at the cursor")
    ap.add_argument("--write", metavar="FILE", help="write the reply's first block of code to FILE")
    a = ap.parse_args()
    if a.mode == "complete":
        complete(a.target, a.open, a.accept)
    else:
        ask(a.target, a.open, a.write)


if __name__ == "__main__":
    main()
PY

block examples
put scratch/subject.py <<'PY'
import subprocess
import sys

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first
"""
diff = subprocess.run(["git", "show", "--format=", "HEAD"], capture_output=True, text=True).stdout
prompt = "Write a commit message for this diff. One line.\n\n" + diff
if "--examples" in sys.argv:
    prompt = EXAMPLES + "\nThe subject is imperative, under sixty characters, with no full stop.\n\n" + prompt
r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=100,
                                          messages=[{"role": "user", "content": prompt}])
print(r.content[0].text)
PY
on 'git log -1 --format=%s'
on 'python scratch/subject.py'
on 'python scratch/subject.py --examples'

block anatomy
on 'python scratch/assist.py ask "Fix parse_price so it accepts commas." --open shop/money.py > /dev/null'
on 'cat -n scratch/reply.txt'
put prompts/comma.md <<'MD'
Goal: `parse_price` in shop/money.py must accept a comma as the decimal
separator, because Brazilian customers type `12,90`.

Context: the function and its tests are below. CONVENTIONS.md is below too;
money is integer cents and a float must never hold it.

Constraints: change only `parse_price`. Keep the arithmetic in integers.
Do not change any existing test.

Done when: `12,90` and `12,9` give 1290, `12.90` still gives 1290, and the
whole suite passes.

Answer with: a unified diff against shop/money.py, and nothing else.
MD
on 'wc -w prompts/comma.md'

block context-not-cleverness
on "python -c 'from shop.money import parse_price; print(parse_price(\"12,90\"))'"
on "python -c 'from shop.money import parse_price; print(parse_price(\"12,90\"))' 2> error.txt; cat error.txt"
on 'python scratch/assist.py ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md --write comma.diff > /dev/null'
on 'cat comma.diff'

block output-format
on 'git apply --check comma.diff && echo "applies cleanly"'
on "sed -i 's/^Answer with: .*/Answer with: only the new parse_price function, in one block of code, and nothing else./' prompts/comma.md && tail -n 1 prompts/comma.md"
put scratch/swap.py <<'PY'
"""Put a function from one file in place of the function of the same name in another.

    python scratch/swap.py TARGET NEW

NEW must hold exactly one function and nothing else, and TARGET must already
have a function of that name at the top level. Anything else is refused before
TARGET is touched, which is the check an Apply button should make.
"""
import ast
import sys

target, new = sys.argv[1], sys.argv[2]
code = open(new).read()
tree = ast.parse(code)
if len(tree.body) != 1 or not isinstance(tree.body[0], ast.FunctionDef):
    sys.exit(f"swap: {new} is not one function and nothing else")
name = tree.body[0].name
lines = open(target).read().split("\n")
old = [f for f in ast.parse("\n".join(lines)).body if isinstance(f, ast.FunctionDef) and f.name == name]
if not old:
    sys.exit(f"swap: {target} has no function called {name}")
lines[old[0].lineno - 1:old[0].end_lineno] = code.rstrip("\n").split("\n")
open(target, "w").write("\n".join(lines))
print(f"swap: {name} replaced in {target}")
PY
on 'python scratch/assist.py ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null'
on 'cat scratch/parse_price.py'
on 'python scratch/swap.py shop/money.py scratch/parse_price.py && git diff'
on "python -c 'from shop.money import parse_price; print(parse_price(\"12,90\"), parse_price(\"12,9\"), parse_price(\"12.90\"))'"
on 'python -m pytest -q'

block decompose
on 'git checkout -q shop/money.py && git status --short'
on 'python scratch/assist.py ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md > /dev/null'
on 'cat -n scratch/reply.txt'
put tests/test_comma.py <<'PY'
import pytest

from shop.money import parse_price


@pytest.mark.parametrize("text", ["12,90", "12.90", "12,9", " 12,90 "])
def test_a_comma_or_a_dot_is_the_decimal_separator(text):
    assert parse_price(text) == 1290


def test_a_price_with_both_a_dot_and_a_comma_is_refused():
    with pytest.raises(ValueError):
        parse_price("1.234,56")
PY
on 'python -m pytest -q tests/test_comma.py | tail -n 3'
on 'python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q tests/test_comma.py | tail -n 3'

block iterate
on 'python -m pytest -q --tb=line tests/test_comma.py > failure.txt; cat failure.txt'
for try in 1 2 3; do
  block iterate-try-$try
  on 'python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null'
  on 'cat scratch/parse_price.py'
  on 'python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt'
  if lab exec ana 'python -m pytest -q' >/dev/null 2>&1; then
    break
  fi
done
if ! lab exec ana 'python -m pytest -q' >/dev/null 2>&1; then
  block iterate-by-hand
  put scratch/parse_price.py <<'PY'
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' or '12,90' -> 1290."""
    text = text.strip()
    if "." in text and "," in text:
        raise ValueError(f"a dot and a comma in one price: {text!r}")
    units, _, cents = text.replace(",", ".").partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
PY
  on 'git checkout -q shop/money.py && python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q'
fi

block evaluate
put scratch/eval_subjects.py <<'PY'
"""Ask for a commit subject for each of the project's commits, with two prompts, and check them."""
import subprocess

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first

The subject is imperative, under sixty characters, with no full stop.
"""
RUNS = 3
client = anthropic.Anthropic()


def subject(diff: str, examples: bool) -> str:
    prompt = (EXAMPLES + "\n" if examples else "") + "Write a commit message for this diff. One line.\n\n" + diff
    r = client.messages.create(model="llama3.2:3b", max_tokens=100,
                               messages=[{"role": "user", "content": prompt}])
    return r.content[0].text.strip()


def problems(s: str) -> list[str]:
    first = s.split()[0].lower()
    found = []
    if "\n" in s:
        found.append("more than one line")
    if len(s.split("\n")[0]) > 60:
        found.append("too long")
    if s.endswith("."):
        found.append("full stop")
    if first.endswith(("ed", "ing")) or (first.endswith("s") and not first.endswith("ss")):
        found.append("not imperative")
    return found


shas = subprocess.run(["git", "log", "--format=%h", "main"], capture_output=True, text=True).stdout.split()
for examples in (False, True):
    passed = 0
    print("with examples" if examples else "without examples")
    for sha in shas:
        diff = subprocess.run(["git", "show", "--format=", sha], capture_output=True, text=True).stdout
        for _ in range(RUNS):
            s = subject(diff, examples)
            p = problems(s)
            passed += not p
            line = s.split("\n")[0]
            print(f"  {sha}  {'ok ' if not p else 'BAD'}  {line[:50]}{'…' if len(line) > 50 else ''}  {', '.join(p)}")
    print(f"  {passed} of {len(shas) * RUNS} pass")
PY
on 'python scratch/eval_subjects.py'

block prompts-as-code
put prompts/fix.md <<'MD'
Goal: $goal

Context: the files below. CONVENTIONS.md is the project's rules; money is
integer cents and a float must never hold it.

$files

Constraints: change only what the goal needs. Do not change any existing test.

Done when: $done

Answer with: only the function you changed, in one block of code, and nothing else.
MD
put prompts/build.py <<'PY'
"""Build a prompt from a template in prompts/ and the files it names."""
from pathlib import Path
from string import Template

import tiktoken

BUDGET = 3000
ENC = tiktoken.get_encoding("o200k_base")


def build(template: str, files: list[str], **fields: str) -> str:
    body = "\n".join(f"### {f}\n{Path(f).read_text()}" for f in ["CONVENTIONS.md", *files])
    prompt = Template(Path("prompts", template).read_text()).substitute(files=body, **fields)
    if len(ENC.encode(prompt)) > BUDGET:
        raise ValueError(f"{template}: over the budget of {BUDGET} tokens")
    return prompt
PY
put tests/test_prompts.py <<'PY'
import pytest

from prompts.build import build

FILES = ["shop/money.py", "tests/test_money.py"]


def test_every_field_is_filled():
    prompt = build("fix.md", FILES, goal="accept a decimal comma", done="the suite passes")
    assert "$" not in prompt


def test_a_missing_field_is_an_error_not_a_blank():
    with pytest.raises(KeyError):
        build("fix.md", FILES, goal="accept a decimal comma")


def test_the_conventions_are_always_included():
    prompt = build("fix.md", FILES, goal="g", done="d")
    assert "integer number of cents" in prompt


def test_the_prompt_fits_the_budget():
    build("fix.md", ["shop/money.py", "shop/cart.py", "shop/coupons.py"], goal="g", done="d")
PY
on 'touch prompts/__init__.py && python -m pytest -q tests/test_prompts.py'
on 'git add prompts/ tests/test_prompts.py && git commit -qm "Keep prompts in the repository, with tests" && git show --stat --format=%s HEAD'
