---
title: Why delimit at all
version: 1
---

A prompt arrives at the model as one stream of text. **Your instructions and the customer's words
are the same kind of characters**, and nothing but the text itself says where one stops and the
other starts. A delimiter is a mark you put around the customer's words so that the boundary is
written down instead of guessed.

The prompt from lesson 6 has none. Its last line is the message:

```
ana@lab:~/triage$ tail -n 3 prompts/v4-only-json.txt
Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
ana@lab:~/triage$ pl render prompts/v4-only-json.txt --cases cases/pasted.jsonl --case p04 | tail -n 7 | cat -n
     1	
     2	Message: The courier left this note:
     3	```
     4	Attempted delivery 14:02
     5	No safe place
     6	```
     7	When will they try again?
```

`pl render` fills the template with one case and prints the prompt exactly as the model would get
it; `cat -n` numbers the lines, for a reason the next section explains. The message starts after
`Message:` and runs to the end of the prompt. That works while the customer's words are the last
thing in the prompt and contain nothing that looks like structure. `cases/pasted.jsonl` holds six
messages that break the second condition: customers who pasted an error, a bank statement line or a
courier's note, the way people do.

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl
6 calls, prompt 651820d7, written to runs/pasted-v4.jsonl
ana@lab:~/triage$ grep '"p01"' cases/pasted.jsonl
{"id": "p01", "message": "The ebook I bought won't download. The page shows ```Error 403: link expired``` instead.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p01
│ {
│   "category": "other",
│   "urgency": "normal",
│   "summary": "Error 403: link expired"
│ }
stop: end, tokens in 104, out 29
```

The summary is the error message the customer pasted, and the category is `other`. The stand-in's
rule is written in its opening comment: it looks for the message inside `<message>` tags, then
inside the last pair of triple backticks, and only then after `Message:`. This prompt marks nothing,
so **the customer's backticks were the only delimiter in sight, and the stand-in took them**. A
real model is not running that rule, but it faces the same question with nothing to answer it, and
**a prompt that marks nothing leaves the boundary to a guess**.
