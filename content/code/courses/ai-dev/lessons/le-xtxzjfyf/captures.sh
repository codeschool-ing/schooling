#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full.
#
# EVERY MODEL REPLY IN THIS LESSON WAS WRITTEN BY THE COURSE. assist is the
# lab's (lab/assist.py) and asks labllm's scripted-1, whose replies are in
# lab/scripted.json. They carry the mistakes the lesson is about on purpose;
# the prompts, git apply, the tests and the evaluation harness are real.
#
# pytest ends with how long its run took, "8 passed in 0.57s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

block anatomy
on 'assist ask "Fix parse_price so it accepts commas." --open shop/money.py'
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
on 'assist ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md > comma.diff'
on 'cat comma.diff'

block output-format
on 'git apply --check comma.diff && echo "applies cleanly"'
on "sed 's/^-    units/-    unit/' comma.diff | git apply --check"
on 'git apply comma.diff && python -m pytest -q'

put lab/subject.py <<'PY'
import subprocess
import sys

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first
"""
diff = subprocess.run(["git", "diff", "HEAD"], capture_output=True, text=True).stdout
prompt = "Write a commit message for this diff. One line.\n\n" + diff
if "--examples" in sys.argv:
    prompt = EXAMPLES + "\nThe subject is imperative, under sixty characters, with no full stop.\n\n" + prompt
r = anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=100,
                                          messages=[{"role": "user", "content": prompt}])
print(r.content[0].text)
PY

block decompose
on 'git checkout -q shop/money.py && git status --short'
on 'assist ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md 2>/dev/null'
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
on 'python -m pytest -q tests/test_comma.py 2>&1 | tail -3'
on 'git apply comma.diff && python -m pytest -q tests/test_comma.py'

block iterate
on 'python -m pytest -q tests/test_comma.py 2>&1 | grep -A3 "def test_a_price_with_both" | head -4; python -m pytest -q tests/test_comma.py 2>&1 | tail -2 > failure.txt'
on 'assist ask "Your change to parse_price fails this test, which must pass: parse_price(\"1.234,56\") must raise ValueError. pytest says: $(cat failure.txt). Reply with a unified diff against the current shop/money.py." --open shop/money.py tests/test_comma.py > second.diff'
on 'cat second.diff'
on 'git apply second.diff && python -m pytest -q'

block examples-run
on 'python lab/subject.py'
on 'python lab/subject.py --examples'

block evaluate
put lab/eval_subjects.py <<'PY'
"""Ask for a commit subject for each of the project's commits, with two prompts, and check them."""
import subprocess

import anthropic

EXAMPLES = """Examples of this project's commit subjects:
Refuse a coupon after its last day
Keep shipping free from 200.00 after the discount
Format negative prices with the sign first

The subject is imperative, under sixty characters, with no full stop.
"""
client = anthropic.Anthropic()


def subject(diff: str, examples: bool) -> str:
    prompt = (EXAMPLES + "\n" if examples else "") + "Write a commit message for this diff. One line.\n\n" + diff
    r = client.messages.create(model="scripted-1", max_tokens=100,
                               messages=[{"role": "user", "content": prompt}])
    return r.content[0].text.strip()


def problems(s: str) -> list[str]:
    first = s.split()[0].lower()
    found = []
    if len(s) > 60:
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
        s = subject(diff, examples)
        p = problems(s)
        passed += not p
        print(f"  {sha}  {'ok ' if not p else 'BAD'}  {s[:58]}{'…' if len(s) > 58 else ''}  {', '.join(p)}")
    print(f"  {passed} of {len(shas)} pass")
PY
on 'python lab/eval_subjects.py'

block prompts-as-code
put prompts/fix.md <<'MD'
Goal: $goal

Context: the files below. CONVENTIONS.md is the project's rules; money is
integer cents and a float must never hold it.

$files

Constraints: change only what the goal needs. Do not change any existing test.

Done when: $done

Answer with: a unified diff, and nothing else.
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
