---
title: Comparing two prompts with numbers
version: 2
---

"The new prompt seems better" is a judgement made on the two or three replies somebody happened to
read. **An evaluation runs both prompts over the same set of cases and scores every reply with the
same checks.** It does not need to be large to be better than a feeling: five cases with automatic
checks already tell you more than a careful reading of one.

## A small evaluation

The cases are the shop's own five commits, which come with diffs. The task is the one from lesson 5
section 04, a commit subject, and the checks are the project's rules for one: one line, under sixty
characters, no full stop, imperative:

```schooling-example
{
  "language": "python",
  "file": "scratch/eval_subjects.py",
  "parts": [
    {
      "code": "\"\"\"Ask for a commit subject for each of the project's commits, with two prompts, and check them.\"\"\"\nimport subprocess\n\nimport anthropic\n\n"
    },
    {
      "code": "EXAMPLES = \"\"\"Examples of this project's commit subjects:\nRefuse a coupon after its last day\nKeep shipping free from 200.00 after the discount\nFormat negative prices with the sign first\n\nThe subject is imperative, under sixty characters, with no full stop.\n\"\"\"\nRUNS = 3\nclient = anthropic.Anthropic()\n\n\n",
      "note": "**The rule, stated, and three examples of it**, the few-shot prompt of lesson 5 section 04. `RUNS` asks for each case three times, because each reply is a draw (lesson 1 section 08) and one draw per case would score the luck of that draw."
    },
    {
      "code": "def subject(diff: str, examples: bool) -> str:\n    prompt = (EXAMPLES + \"\\n\" if examples else \"\") + \"Write a commit message for this diff. One line.\\n\\n\" + diff\n    r = client.messages.create(model=\"llama3.2:3b\", max_tokens=100,\n                               messages=[{\"role\": \"user\", \"content\": prompt}])\n    return r.content[0].text.strip()\n\n\n",
      "note": "**One request per case**, with or without the examples. Everything else in the two runs is identical, so a difference in score is the prompt's."
    },
    {
      "code": "def problems(s: str) -> list[str]:\n    first = s.split()[0].lower()\n    found = []\n    if \"\\n\" in s:\n        found.append(\"more than one line\")\n    if len(s.split(\"\\n\")[0]) > 60:\n        found.append(\"too long\")\n    if s.endswith(\".\"):\n        found.append(\"full stop\")\n    if first.endswith((\"ed\", \"ing\")) or (first.endswith(\"s\") and not first.endswith(\"ss\")):\n        found.append(\"not imperative\")\n    return found\n\n\n",
      "note": "**The checks, as code.** Each returns the list of what is wrong, so a failure says why rather than only that. Only the first line is judged for length, and a reply of several lines fails on that alone."
    },
    {
      "code": "shas = subprocess.run([\"git\", \"log\", \"--format=%h\", \"main\"], capture_output=True, text=True).stdout.split()\nfor examples in (False, True):\n    passed = 0\n    print(\"with examples\" if examples else \"without examples\")\n    for sha in shas:\n        diff = subprocess.run([\"git\", \"show\", \"--format=\", sha], capture_output=True, text=True).stdout\n        for _ in range(RUNS):\n            s = subject(diff, examples)\n            p = problems(s)\n            passed += not p\n            line = s.split(\"\\n\")[0]\n            print(f\"  {sha}  {'ok ' if not p else 'BAD'}  {line[:50]}{'…' if len(line) > 50 else ''}  {', '.join(p)}\")\n    print(f\"  {passed} of {len(shas) * RUNS} pass\")\n",
      "note": "**Every case, both prompts, a score each.** The cases are the project's own commits, read from git, and the output is cut at fifty characters so each attempt fits on one line."
    }
  ]
}
```

```
ana@dev:~/shop$ python scratch/eval_subjects.py
without examples
  19265e0  BAD  "Added shop conventions for code, money, and testi…  not imperative
  19265e0  BAD  "Added project conventions and code style guide to…  too long, not imperative
  19265e0  BAD  "Added conventions for money, code, tests, and com…  too long, not imperative
  b88cbb3  BAD  "Added README for small online shop example"  not imperative
  b88cbb3  BAD  "Added shop example to README"  not imperative
  b88cbb3  BAD  "Added shop example to README.md"  not imperative
  c2b5d79  BAD  "Added coupon logic and tests for shop cart"  not imperative
  c2b5d79  BAD  "Added coupon and cart classes for managing discou…  not imperative
  c2b5d79  BAD  "Added coupon functionality and tests to shop modu…  not imperative
  fe437dd  BAD  "Added Cart class and tests for shop cart function…  not imperative
  fe437dd  BAD  "Added Cart and Line dataclasses with calculation …  not imperative
  fe437dd  BAD  "Added Cart class and tests with shipping, discoun…  too long, not imperative
  33fefcf  BAD  Added initial files and tests for money functional…  full stop, not imperative
  33fefcf  BAD  "Added money module with price parsing and formatt…  too long, not imperative
  33fefcf  BAD  "Added shop module with money functionality"  not imperative
  0 of 15 pass
with examples
  19265e0  ok   Format negative prices with the sign first  
  19265e0  ok   Refactor money formatting for negative prices  
  19265e0  ok   Format negative prices with the sign first  
  b88cbb3  ok   Format README.md for shop documentation  
  b88cbb3  BAD  Fixed README formatting  not imperative
  b88cbb3  ok   Update README with cart explanation  
  c2b5d79  ok   Refuse unknown coupon  
  c2b5d79  ok   Refuse unknown coupon  
  c2b5d79  ok   Update coupon application and testing  
  fe437dd  ok   "Add cart functionality with shipping"  
  fe437dd  ok   "Implement Cart class with shipping and discount"  
  fe437dd  ok   `Add shipping calculations to Cart class`  
  33fefcf  ok   Format negative prices with the sign first  
  33fefcf  ok   Format negative prices with the sign first  
  33fefcf  ok   Format negative prices with the sign first  
  14 of 15 pass
```

**None of fifteen without examples, fourteen of fifteen with them.** That is a measurement, of this
model on these five diffs on one day, and it says the examples fix the form, which section 04 could
only suggest from one reply. Every failure on the first run is the same habit, `Added …`, and most
of them come in quotation marks the checks do not look for.

Now read the passes. Five of the fourteen are `Format negative prices with the sign first`, one of
the examples, for two commits that never touch a negative price: the conventions and the first
version of `money.py`. Two more are wrapped in quotation marks and one in backticks, which the
project does not write either. **The checks measured exactly what they were written to measure**, and
an example copied word for word meets every rule of form. A sixth check, a subject equal to an
example fails, would take the score from fourteen to nine, and that is the next thing ana adds,
because a check is cheaper to write than the argument about whether the score was real.

That is how an evaluation grows: a run, a reading of what passed, and a check for what should not
have. The score is only as good as the checks behind it.

## What makes an evaluation useful

- **Checks a program can make.** Length, format, a parse, a test that runs, a word from a fixed list,
  a reply that is not a copy of the prompt.
  Where a check needs judgement (is this summary faithful?), a person scores a sample; some teams use
  a second model as the judge, which is itself a prompt that needs evaluating.
- **Cases from real use.** Inputs collected from the feature's own traffic, including the ones that
  went wrong. Each bug report becomes a case, so it cannot come back unnoticed.
- **Run on every change to the prompt, and to the model.** A prompt that scored well on one model
  can score differently on the next version, or on `llama3.2:1b`. Lesson 10 changes providers; this is the harness that
  says what the change cost.
- **Kept small enough to run often.** Thirty short requests take a couple of minutes on the
  recording machine. A hundred cases that run in a few minutes get run; a thousand that take an afternoon get
  skipped.

The prompt, the cases and the checks all go in the repository, beside the code they test.
