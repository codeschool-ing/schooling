---
title: Showing instead of describing
version: 1
---

Some requirements are easier to show than to state. "Write commit subjects in our style" is vague;
three real subjects from the project are not. Putting a few examples of the output you want in the
prompt is called **few-shot prompting**, and it is the strongest tool there is for format and style:
the model continues the pattern it was shown.

## A commit subject, two ways

ana's script asks for a commit subject for her uncommitted change to `parse_price`, once with only
the diff, and once with three example subjects and the rule they follow:

```python
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
```

```
ana@dev:~/shop$ python lab/subject.py
Updated the parse_price function to support a comma as the decimal separator and added validation for invalid inputs.
ana@dev:~/shop$ python lab/subject.py --examples
Accept a decimal comma in parse_price
```

The first reply describes the change in the past tense, at length, with a full stop. It is accurate
and it is not what this project writes. The second matches the examples: imperative, short, no full
stop, the same rule `CONVENTIONS.md` states for commits. Both replies were written by the course to
show the difference the technique makes; lesson 5 section 09 measures that difference over more
than one case.

## Choosing the examples

- **Real ones, from your own material.** Examples invented for the prompt drift towards what the
  author imagines rather than what the project does.
- **Different from each other.** Three subjects about the same file teach the model that subjects
  are about that file. Vary the thing that should vary, so only the shared pattern is copied.
- **Not the answer.** An example too close to the actual task is copied rather than generalised
  from; it shows up word for word in the reply.
- **Few.** Three is often enough for a format. Each example is tokens on every request, and lesson
  2's arithmetic applies to them like everything else.

Examples teach form far better than they teach correctness. A few-shot prompt for a classifier will
make every reply look like a label; whether it is the right label is what lesson 5 section 09
checks.
