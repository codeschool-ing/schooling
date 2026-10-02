---
title: XML tags
version: 1
---

The same prompt with the backticks replaced by a pair of tags:

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
6 calls, prompt 39f70d15, written to runs/tagged.jsonl
ana@lab:~/triage$ pl check runs/tagged.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      6     0
urgency       5     1
all           5     1

p03    urgency   normal, expected low
ana@lab:~/triage$ pl compare runs/backticks.jsonl runs/tagged.jsonl
runs/backticks.jsonl     passes 1/6
runs/tagged.jsonl        passes 5/6
fixed 4, broken 0, still passing 1, still failing 1
sign test on the 4 that changed: p = 0.125
ana@lab:~/triage$ pl show runs/tagged.jsonl p04
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The courier left this note: ``` Attempted delivery 14:02 No safe place ``` When will they try again?"
│ }
stop: end, tokens in 132, out 50
```

Five in six, and the one left, `p03`, is an urgency that both prompts get wrong for reasons that
have nothing to do with delimiters. `p04` now carries the whole message, the courier's note
included, with the customer's backticks as ordinary characters inside it.

The sign test is not impressed: four changed messages give p = 0.125, and lesson 7 showed that it
takes six in one direction to get under 0.05. **Here the evidence is in the replies, not in the
count.** You can read what each prompt took as the message, and the mechanism is the same in every
failure. Six messages written to show one known failure are a regression test, and they stay in the
test set so that the failure cannot come back unnoticed.

## Why tags do better

- **They are rare in what customers write.** Backticks turn up in anything technical; a line
  reading `</message>` almost never does.
- **They have a name.** A closing backtick fence closes whichever block is open, while `</message>`
  says which section ends. A prompt with several pieces of data, `<message>`, `<order>`,
  `<previous_messages>`, can mark each one and refer to it by name in the instructions.
- **Models are trained on a great deal of it.** HTML and XML are everywhere in the text models
  learn from, and Anthropic's prompting documentation has a page called *Use XML tags to structure
  your prompts* that recommends exactly this. No particular tag names are special; what helps is
  using them consistently and naming them in the instructions, as `v5-tagged.txt` does.

Rare is not never, though. One of the six pasted messages, `p05`, quotes an error page that says
`</message> is not allowed`. The next section takes a message that does that on purpose.
