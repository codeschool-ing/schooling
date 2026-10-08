---
title: Prompts are code
version: 2
---

A prompt that a feature sends to a model is part of the program. It decides what the feature does
as much as any function does, and it breaks in the same ways: a field left out, a file grown past
the budget, a change nobody reviewed. **So it lives where code lives**: in the repository, reviewed
in pull requests, built by a function, covered by tests.

## A template and a builder

ana turns the comma prompt of lesson 5 section 02, with the last line it ended up with in section
05, into a template, with `$` fields for what changes from one task to the next:

```
Goal: $goal

Context: the files below. CONVENTIONS.md is the project's rules; money is
integer cents and a float must never hold it.

$files

Constraints: change only what the goal needs. Do not change any existing test.

Done when: $done

Answer with: only the function you changed, in one block of code, and nothing else.
```

and a builder that fills it, always adds `CONVENTIONS.md`, and refuses a prompt over budget:

```schooling-example
{
  "language": "python",
  "file": "prompts/build.py",
  "parts": [
    {
      "code": "\"\"\"Build a prompt from a template in prompts/ and the files it names.\"\"\"\nfrom pathlib import Path\nfrom string import Template\n\nimport tiktoken\n\n"
    },
    {
      "code": "BUDGET = 3000\nENC = tiktoken.get_encoding(\"o200k_base\")\n\n\n",
      "note": "**A budget for the whole prompt**, counted with the same encoding as lesson 1."
    },
    {
      "code": "def build(template: str, files: list[str], **fields: str) -> str:\n    body = \"\\n\".join(f\"### {f}\\n{Path(f).read_text()}\" for f in [\"CONVENTIONS.md\", *files])\n",
      "note": "**The conventions go in every time**, first, whatever the caller names. A rule that depends on every caller remembering it is a rule that is sometimes missing."
    },
    {
      "code": "    prompt = Template(Path(\"prompts\", template).read_text()).substitute(files=body, **fields)\n    if len(ENC.encode(prompt)) > BUDGET:\n        raise ValueError(f\"{template}: over the budget of {BUDGET} tokens\")\n    return prompt\n",
      "note": "**Fill the template strictly, then check the size.** A prompt over budget is refused here, before it costs anything."
    }
  ]
}
```

## Tests for a prompt

The tests check the things that break silently, which are exactly the things a person reading the
prompt in a log would not notice:

```python
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
```

```
ana@dev:~/shop$ touch prompts/__init__.py && python -m pytest -q tests/test_prompts.py
....                                                                     [100%]
4 passed in 1.87s
```

**`Template.substitute` raises `KeyError` for a missing field**, where the alternative,
`safe_substitute`, would send the model the literal text `$done`, which it would read as part of
the task. A failing test is the better outcome. The budget test is lesson 2 section 09's guard,
written down once, and it fails the day somebody adds a large file to the default context.

What these tests do not do is call a model. They test what is sent, which is deterministic and
free; what comes back is lesson 5 section 09's subject.

## Into the repository

```
ana@dev:~/shop$ git add prompts/ tests/test_prompts.py && git commit -qm "Keep prompts in the repository, with tests" && git show --stat --format=%s HEAD
Keep prompts in the repository, with tests

 prompts/__init__.py   |  0
 prompts/build.py      | 16 ++++++++++++++++
 prompts/comma.md      | 13 +++++++++++++
 prompts/fix.md        | 12 ++++++++++++
 tests/test_prompts.py | 24 ++++++++++++++++++++++++
 5 files changed, 65 insertions(+)
```

From now on a change to what the shop asks a model is a diff somebody can review, with a reason in
the commit, and `git log -- prompts/` is the history of every instruction the feature has ever
given.
