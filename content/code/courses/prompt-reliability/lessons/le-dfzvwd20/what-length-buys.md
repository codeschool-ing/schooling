---
title: What a longer prompt buys
version: 1
---

A prompt grows the way a policy document grows. Somebody sees one bad answer and adds a line,
somebody else adds the same line in capitals, and nobody deletes anything, because deleting feels
riskier than adding. **The idea underneath is that a longer prompt is a more careful one.** It is
only a longer one, and the length has a price that is paid on every call.

Here is the triage prompt after a few weeks of that kind of care:

```
ana@lab:~/triage$ cat -n prompts/v2-long.txt
     1	You are a helpful, friendly and professional assistant for Folio, an online bookshop.
     2	Your job is to read customer messages and sort them so the support team can answer them.
     3	
     4	Keep the summary brief so the team can scan the queue quickly.
     5	
     6	Answer in JSON with three fields:
     7	- "category": one of billing, delivery, returns, account, other
     8	- "urgency": one of low, normal, high
     9	- "summary": what the customer needs
    10	
    11	IMPORTANT: Do not make up information that is not in the message.
    12	Do not add fields that are not listed above.
    13	Never include the customer's name or email in the summary.
    14	IMPORTANT: Do not make up information that is not in the message.
    15	
    16	The team reads the summary instead of the message, so describe the problem in full detail.
    17	
    18	Message: {{message}}
ana@lab:~/triage$ pl tokens prompts/v2-json.txt
69 tokens, 46 words, 295 characters
ana@lab:~/triage$ pl tokens prompts/v2-long.txt
167 tokens, 131 words, 764 characters
```

`v2-json.txt` is the prompt lesson 1 ran when it first asked for JSON: 69 tokens. The long one
asks for the same three fields with the same two lists, and takes 167. The other 98 tokens are a
persona, three rules about what not to do with one of them written twice, and two instructions
about the summary that disagree with each other. The next section is about those two.

## Paid on every call

The prompt is sent whole with every message. **Whatever the instructions cost, you pay it forty
times for forty messages and a million times for a million.** The lab's prices are in a file, and
`pl cost` adds up what a run spent:

```
ana@lab:~/triage$ cat prices.json
{
  "model": "standin-1",
  "note": "cents per million tokens; written by the course, not any provider's price list",
  "input": 300,
  "cache_read": 30,
  "cache_write": 375,
  "output": 1500
}
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl
40 calls, prompt 2b255df5, written to runs/long.jsonl
ana@lab:~/triage$ pl cost runs/v2.jsonl
tokens          count   per call
input            3139       78.5
cache_read          0        0.0
cache_write         0        0.0
output           1595       39.9

cost of these 40 calls: 3.3342 cents
cost of a million calls like them: 83,355 cents
ana@lab:~/triage$ pl cost runs/long.jsonl
tokens          count   per call
input            7059      176.5
cache_read          0        0.0
cache_write         0        0.0
output           1709       42.7

cost of these 40 calls: 4.6812 cents
cost of a million calls like them: 117,030 cents
```

Input per call went from 78.5 tokens to 176.5. That gap is the 98 tokens of extra instructions,
the same on every message whatever the message says. Output moved much less, from 39.9 to 42.7.
At the course's prices a million calls cost 83,355 cents with the short prompt and 117,030 with
the long one, **about 40% more for answers that are no better**, which the last section of this
lesson measures.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Tokens per call, averaged over the forty messages. The short prompt: 69 of instructions, 9.5 of message, 39.9 written. The long prompt: 167 of instructions, 9.5 of message, 42.7 written.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Tokens per call, mean of 40</text><text x=\"118\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-json.txt</text><rect x=\"130\" y=\"50\" width=\"144.9\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"274.9\" y=\"50\" width=\"19.9\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"294.8\" y=\"50\" width=\"83.8\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"388.6\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">118.4</text><text x=\"118\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v2-long.txt</text><rect x=\"130\" y=\"102\" width=\"350.7\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><rect x=\"480.7\" y=\"102\" width=\"19.9\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"500.6\" y=\"102\" width=\"89.7\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"600.3\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">219.2</text><rect x=\"130\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"148\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instructions</text><rect x=\"300\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"318\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the message</text><rect x=\"470\" y=\"166\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"488\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the reply</text></svg>", "caption": "The message is the same size under both prompts and the reply grows by under three tokens. Nearly all of the difference is instructions, paid again on every call."}
```

The prices are the course's, and the file says so. The shape is the usual one: Anthropic's and
OpenAI's published price lists both charge more for a token the model writes than for one it
reads. In this run that does not save the long prompt, because it adds 3,920 tokens of input
over the forty calls and only 114 of output. Lesson 16 does this arithmetic for a whole pipeline,
and lesson 17 shows how a cache makes the fixed part of a prompt cheaper. **Neither makes a
useless instruction worth sending.**

## What a reader does with length

The model is not the only reader. The person who opens `v2-long.txt` next month to fix a
complaint has eighteen lines to hold in their head, and has to work out which of them still
matter. Line 14 repeats line 11 word for word. Lines 11 and 14 are in capitals, which tells that
person that they matter more than line 13, and nobody decided that. **Every line in a prompt is a
claim that it changes an answer**, and a reader has no way to know which claims are true except
by testing them.
