---
title: Showing instead of describing
version: 2
---

Some requirements are easier to show than to state. "Write commit subjects in our style" is vague;
three real subjects from the project are not. Putting a few examples of the output you want in the
prompt is called **few-shot prompting**, and it is the strongest tool there is for format and style:
the model continues the pattern it was shown.

## A commit subject, two ways

`CONVENTIONS.md` says a commit subject is imperative and under sixty characters. The shop's own
five commits were made before anybody wrote that down, and they are single nouns: `Conventions`,
`README`, `Coupons`. ana's script, `scratch/subject.py`, asks for a subject for the latest commit, once with only its
diff, and once with three subjects written to the rule and the rule itself:

```python
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
```

```
ana@dev:~/shop$ git log -1 --format=%s
Conventions
ana@dev:~/shop$ python scratch/subject.py
"Added Conventions file with coding and testing standards"
ana@dev:~/shop$ python scratch/subject.py --examples
Format negative prices with the sign first
```

The first reply is in quotation marks and in the past tense. It is accurate, and it is not what this project writes. The second has exactly the right form, imperative,
short, no full stop, and it is **one of the examples, word for word**. The commit it describes adds
`CONVENTIONS.md`; it has nothing to do with negative prices. The model copied the pattern so
closely that it copied the content too.

That is both halves of the technique in two lines. The examples fixed the form at once, and they
told the model nothing about what this diff does. Lesson 5 section 09 runs the same two prompts
over every commit, three times each, and counts both.

## Choosing the examples

- **Real ones, from your own material**, when you have them. Examples invented for the prompt drift
  towards what the author imagines rather than what the project does. ana's history had none that
  followed the rule, so she wrote three, which is the next best thing.
- **Different from each other.** Three subjects about the same file teach the model that subjects
  are about that file. Vary the thing that should vary, so only the shared pattern is copied.
- **Not the answer, and not close to it.** An example near the actual task is copied rather than
  generalised from, and a small model copies even a distant one, as above. The check for that is
  cheap: a reply equal to one of the examples is wrong.
- **Few.** Three is often enough for a format. Each example is tokens on every request, and lesson
  2's arithmetic applies to them like everything else.

Examples teach form far better than they teach correctness. A few-shot prompt for a classifier will
make every reply look like a label; whether it is the right label is what lesson 5 section 09
checks.
