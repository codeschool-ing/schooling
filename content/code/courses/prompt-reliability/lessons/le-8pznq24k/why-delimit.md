---
title: Why delimit at all
version: 2
---

A prompt arrives at the model as one stream of text. **Your instructions and the customer's words
are the same kind of characters**, and nothing but the text itself says where one stops and the
other starts. A delimiter is a mark you put around the customer's words so that the boundary is
written down instead of guessed.

Most messages give a boundary nothing to do. The ones that test it are messages with structure of
their own: customers paste an error page, a line of a bank statement, a courier's note, and those
arrive with backticks, line breaks and tags in them. Here are six, labelled the way a person on the
support team would label them. Save them as `cases/pasted.jsonl`:

```
{"id": "p01", "message": "The ebook I bought won't download. The page shows ```Error 403: link expired``` instead.", "expect": {"category": "returns", "urgency": "normal"}}
{"id": "p02", "message": "My bank statement shows ```FOLIO BOOKS LTD  £15.00``` but I paid £12 at checkout.", "expect": {"category": "billing", "urgency": "normal"}}
{"id": "p03", "message": "The emails you send to my account show <b>Order 5512</b> as raw tags.", "expect": {"category": "account", "urgency": "low"}}
{"id": "p04", "message": "The courier left this note:\n```\nAttempted delivery 14:02\nNo safe place\n```\nWhen will they try again?", "expect": {"category": "delivery", "urgency": "normal"}}
{"id": "p05", "message": "My review won't post. It says </message> is not allowed, but I never typed that.", "expect": {"category": "other", "urgency": "normal"}}
{"id": "p06", "message": "Tracking shows ``` and then nothing. Is my parcel lost?", "expect": {"category": "delivery", "urgency": "normal"}}
```

`v4-only-json.txt`, the prompt from lesson 3, has no delimiter. Its last line is the message:

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
`Message:` and runs to the end of the prompt. That holds while the customer's words are the last
thing in the prompt and contain nothing that looks like structure, and `p04` already contains a
block of its own, fenced in backticks. Run the six:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl
6 calls, prompt 651820d7, llama3.2:3b, written to runs/pasted-v4.jsonl
ana@lab:~/triage$ pl check runs/pasted-v4.jsonl --failures
check      pass  fail
json          6     0
fields        6     0
labels        6     0
category      2     4
urgency       0     6
all           0     6

p01    category  delivery, expected returns
p02    category  returns, expected billing
p03    category  delivery, expected account
p04    urgency   low, expected normal
p05    category  returns, expected other
p06    urgency   high, expected normal
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p01
│ {"category": "delivery", "urgency": "high", "summary": "Ebook download failed due to expired link"}
stop: stop, tokens in 128, out 27, 38.6 s
ana@lab:~/triage$ pl show runs/pasted-v4.jsonl p04
│ {"category": "delivery", "urgency": "low", "summary": "Customer wants to know when the courier will try again after leaving a note indicating no safe place for delivery."}
stop: stop, tokens in 135, out 40, 5.1 s
```

**Not one reply passes.** Four have the wrong category and the other two the wrong urgency. `p01`,
an ebook that will not download, is labelled `returns` like lesson 1's ebook that would not open,
and the model called it `delivery`. The summaries show that the model read the messages: `p04`'s summary has the courier's note in it,
which is the part a boundary drawn at the wrong place would have lost. So nothing here went wrong
*because* the prompt marks nothing. The model guessed the boundary, and with the message last in the
prompt the guess was easy.

That is the reason to delimit anyway. **A prompt that marks nothing leaves the boundary to a
guess**, and the guess gets harder as soon as anything follows the message: a second piece of data,
an instruction repeated at the end, an example. The next two sections mark it two ways and run the
same six messages, and the counts are the ones to compare with this one: 2 categories right of 6,
no reply passing.
