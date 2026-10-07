---
title: Comparing two prompts with numbers
version: 1
---

"The new prompt seems better" is a judgement made on the two or three replies somebody happened to
read. **An evaluation runs both prompts over the same set of cases and scores every reply with the
same checks.** It does not need to be large to be better than a feeling: five cases with automatic
checks already tell you more than a careful reading of one.

## A small evaluation

The cases are the shop's own five commits, which come with diffs. The task is the one from lesson 5
section 04, a commit subject, and the checks are the project's rules for one: under sixty
characters, no full stop, imperative:

```schooling-example
{
  "language": "python",
  "file": "lab/eval_subjects.py",
  "parts": [
    {
      "code": "\"\"\"Ask for a commit subject for each of the project's commits, with two prompts, and check them.\"\"\"\nimport subprocess\n\nimport anthropic\n\n"
    },
    {
      "code": "EXAMPLES = \"\"\"Examples of this project's commit subjects:\nRefuse a coupon after its last day\nKeep shipping free from 200.00 after the discount\nFormat negative prices with the sign first\n\nThe subject is imperative, under sixty characters, with no full stop.\n\"\"\"\nclient = anthropic.Anthropic()\n\n\n",
      "note": "**The rule, stated, and three examples of it**, the few-shot prompt of lesson 5 section 04."
    },
    {
      "code": "def subject(diff: str, examples: bool) -> str:\n    prompt = (EXAMPLES + \"\\n\" if examples else \"\") + \"Write a commit message for this diff. One line.\\n\\n\" + diff\n    r = client.messages.create(model=\"scripted-1\", max_tokens=100,\n                               messages=[{\"role\": \"user\", \"content\": prompt}])\n    return r.content[0].text.strip()\n\n\n",
      "note": "**One request per case**, with or without the examples. Everything else in the two runs is identical, so a difference in score is the prompt's."
    },
    {
      "code": "def problems(s: str) -> list[str]:\n    first = s.split()[0].lower()\n    found = []\n    if len(s) > 60:\n        found.append(\"too long\")\n    if s.endswith(\".\"):\n        found.append(\"full stop\")\n    if first.endswith((\"ed\", \"ing\")) or (first.endswith(\"s\") and not first.endswith(\"ss\")):\n        found.append(\"not imperative\")\n    return found\n\n\n",
      "note": "**The checks, as code.** Each returns the list of what is wrong, so a failure says why rather than only that."
    },
    {
      "code": "shas = subprocess.run([\"git\", \"log\", \"--format=%h\", \"main\"], capture_output=True, text=True).stdout.split()\nfor examples in (False, True):\n    passed = 0\n    print(\"with examples\" if examples else \"without examples\")\n    for sha in shas:\n        diff = subprocess.run([\"git\", \"show\", \"--format=\", sha], capture_output=True, text=True).stdout\n        s = subject(diff, examples)\n        p = problems(s)\n        passed += not p\n        print(f\"  {sha}  {'ok ' if not p else 'BAD'}  {s[:58]}{'…' if len(s) > 58 else ''}  {', '.join(p)}\")\n    print(f\"  {passed} of {len(shas)} pass\")",
      "note": "**Every case, both prompts, a score each.** The cases are the project's own commits, read from git."
    }
  ]
}
```

```
ana@dev:~/shop$ python lab/eval_subjects.py
without examples
  19265e0  ok   Add CONVENTIONS.md  
  b88cbb3  BAD  Updated README.  full stop, not imperative
  c2b5d79  BAD  Added coupon support.  full stop, not imperative
  fe437dd  BAD  Implemented Cart and Line dataclasses with subtotal, disco…  too long, full stop, not imperative
  33fefcf  BAD  Added parse_price and format_price functions to handle mon…  too long, full stop, not imperative
  1 of 5 pass
with examples
  19265e0  ok   Write down the project's conventions  
  b88cbb3  ok   Explain the project in a README  
  c2b5d79  ok   Add coupon codes with a percentage off  
  fe437dd  ok   Add a cart with lines, a discount and shipping  
  33fefcf  ok   Keep prices as integer cents  
  5 of 5 pass
```

**One of five without examples, five of five with them.** The replies were written by the course to
show the mechanics, so this result is an illustration, not a measurement of any model. What is real
is the harness: the same cases, the same checks, a score per prompt, and every failure listed with its
reason. Against a real model you would run each case several times, since replies vary (lesson 1
section 08), and report how often each prompt passes.

## What makes an evaluation useful

- **Checks a program can make.** Length, format, a parse, a test that runs, a word from a fixed list.
  Where a check needs judgement (is this summary faithful?), a person scores a sample; some teams use
  a second model as the judge, which is itself a prompt that needs evaluating.
- **Cases from real use.** Inputs collected from the feature's own traffic, including the ones that
  went wrong. Each bug report becomes a case, so it cannot come back unnoticed.
- **Run on every change to the prompt, and to the model.** A prompt that scored well on one model
  can score differently on the next version. Lesson 10 changes providers; this is the harness that
  says what the change cost.
- **Kept small enough to run often.** A hundred cases that run in a minute get run; a thousand that
  take an hour get skipped.

The prompt, the cases and the checks all go in the repository, beside the code they test.
