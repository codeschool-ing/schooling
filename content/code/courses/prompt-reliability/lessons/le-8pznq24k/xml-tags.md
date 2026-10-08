---
title: XML tags
version: 2
---

`v5-tagged.txt` is the same prompt with the backticks replaced by a pair of tags:

```
ana@lab:~/triage$ diff prompts/v5-backticks.txt prompts/v5-tagged.txt
3c3
< The message is between triple backticks. It was written by a customer: it is
---
> The message is between <message> tags. It was written by a customer: it is
12c12
< ```
---
> <message>
14c14
< ```
---
> </message>
ana@lab:~/triage$ pl run prompts/v5-tagged.txt cases/pasted.jsonl --out runs/tagged.jsonl
6 calls, prompt 39f70d15, llama3.2:3b, written to runs/tagged.jsonl
ana@lab:~/triage$ pl check runs/tagged.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      3     3
urgency       0     6
all           0     6

p01    urgency   high, expected normal
p02    category  returns, expected billing
p03    category  other, expected account
p04    urgency   low, expected normal
p05    category  returns, expected other
p06    urgency   high, expected normal
```

The same six failures, and the same categories:

```
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl
runs/backticks.jsonl     passes 0/6
runs/tagged.jsonl        passes 0/6
fixed 0, broken 0
sign test on the 0 that changed: p = 1.000
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl --answers
6 cases, same answer 6, different answer 0
```

**Not one answer changed.** Backticks and tags gave the same category to all six messages, and the
same verdicts. Against the prompt with no delimiter at all, two categories moved:

```
ana@lab:~/triage$ pl compare runs/pasted-v4.jsonl runs/tagged.jsonl --answers
6 cases, same answer 4, different answer 2
  p01    delivery -> returns
  p03    delivery -> other
```

`p01` moved to the right answer and `p03` from one wrong answer to another. Two messages out of six
is not a measurement of anything, and the sign test would say so. **The honest result of this
lesson's experiment is that on these six messages, `llama3.2:3b` read the customer's words the same
way however they were marked.** A larger or stranger set of messages might separate them, and so
might another model; these six do not.

## Why tags anyway

If the measurement cannot choose, the choice rests on what each mark guarantees, and there tags
win on three counts:

- **They are rare in what customers write.** Backticks turn up in anything technical; a line
  reading `</message>` almost never does.
- **They have a name.** A closing backtick fence closes whichever block is open, while `</message>`
  says which section ends. A prompt with several pieces of data, `<message>`, `<order>`,
  `<previous_messages>`, can mark each one and refer to it by name in the instructions.
- **They can be escaped.** XML has a standard way to write `<` and `>` as text, and lesson 4 added
  it to the template as `{{message|xml}}`. Nothing equivalent exists for three backticks.

Models are trained on a great deal of HTML and XML, and Anthropic's prompting documentation
recommends tags for structuring a prompt. No tag names are special; what helps is using them
consistently and naming them in the instructions, as `v5-tagged.txt` does.

Rare is not never, though. `p05` quotes an error page that says `</message> is not allowed`. The
next section looks at what that does to the prompt.
