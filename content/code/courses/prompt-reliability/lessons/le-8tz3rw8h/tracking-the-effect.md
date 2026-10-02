---
title: Tracking the effect of each change
version: 1
---

With one file, a history and an id that means something, the obvious next step is to run every
version against the same messages. `pl log` does that in one command: for each commit that touched
`prompts/triage.txt`, oldest first, it takes the file as it was, runs it over a test set and prints
two numbers.

```
ana@lab:~/triage$ pl log
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/40   2366  First triage prompt
90a013e  2026-08-04 24/40   4734  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05 36/40  11036  Add three examples of the answer
9683448  2026-08-07 36/40  11636  Ask for the JSON object and nothing else
931c548  2026-08-10 36/40  13356  Put the message in tags and say it is data
c8470c9  2026-08-11 36/40  13356  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/40   9739  Make the examples easier to read
03e1151  2026-08-17 36/40  13356  Put the examples back in JSON
```

`all` is the count of replies that passed every check, out of the forty dev messages by default.
`tokens` is everything the forty calls consumed, input and output added together. Read down the
two columns rather than across the rows, because **the useful thing is how each number moved from
the commit above it**.


```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 275\" role=\"img\" aria-label=\"The score of prompts/triage.txt on the forty dev messages at each of its eight commits, in order: 0, 24, 36, 36, 36, 36, 0, 36. The tokens of each run: 2366, 4734, 11036, 11636, 13356, 13356, 9739, 13356. The seventh commit, Make the examples easier to read, drops the score to 0 and uses fewer tokens than any commit since 4 August; the eighth puts both back.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passes on dev, out of 40, at each commit</text><path d=\"M80 200 L694 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"90\" y=\"196\" width=\"48\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"114.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"114.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8ec39c2</text><text x=\"114.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2366</text><rect x=\"168\" y=\"113.6\" width=\"48\" height=\"86.4\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"192.0\" y=\"101.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24</text><text x=\"192.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90a013e</text><text x=\"192.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4734</text><rect x=\"246\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"270.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"270.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">f361c0a</text><text x=\"270.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11036</text><rect x=\"324\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"348.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"348.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9683448</text><text x=\"348.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11636</text><rect x=\"402\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"426.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"426.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">931c548</text><text x=\"426.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><rect x=\"480\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"504.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"504.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c8470c9</text><text x=\"504.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><rect x=\"558\" y=\"196\" width=\"48\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"582.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"582.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31a6a59</text><text x=\"582.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9739</text><rect x=\"636\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"660.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"660.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">03e1151</text><text x=\"660.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><text x=\"74\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tokens</text><text x=\"582.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the cheapest since 4 August</text></svg>", "caption": "Every commit of the prompt run against the same forty messages. Two commits cost tokens and moved no score; one made the prompt cheaper and broke all thirty-six of the messages it used to get right."}
```

## The commits that earned their place

`90a013e` took the score from 0 to 24 by asking for JSON, and `f361c0a` from 24 to 36 by adding
examples, the two changes lesson 1 measured. The second more than doubled the tokens, from 4734 to
11036, and it bought twelve messages with them. That is what a change that earned its cost looks
like in this table: one number up, the other up, and a reason to think the first was worth the
second.

## The commits that cost tokens and moved nothing

`9683448`, *"Ask for the JSON object and nothing else"*, added 600 tokens over forty calls and left
the score at 36. Lesson 1 already showed why: once the examples are there, the stand-in writes bare
JSON, so an instruction against code fences has nothing left to fix. `931c548` added another 1720
tokens and the score did not move either. **A flat score on dev does not mean the change did
nothing**; it means dev does not test what the change was for. That commit was about instructions
hidden in a message, and the attack set is where those live:

```
ana@lab:~/triage$ pl log cases/attacks.jsonl
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/10    571  First triage prompt
90a013e  2026-08-04  2/10   1090  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05  1/10   2668  Add three examples of the answer
9683448  2026-08-07  1/10   2818  Ask for the JSON object and nothing else
931c548  2026-08-10  6/10   3302  Put the message in tags and say it is data
c8470c9  2026-08-11  6/10   3329  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/10   2472  Make the examples easier to read
03e1151  2026-08-17  6/10   3329  Put the examples back in JSON
```

On the ten attacks the same commit took the score from 1 to 6, so its tokens bought something
after all. `9683448` is still flat here, at 1 of 10 before and after, and `c8470c9`, the escaping
commit, moves no score on either set. Whatever the model, **a change no test set can see is a
change you are taking on trust**.
Either add the case that shows what it fixes, or write down that it fixes nothing you can measure.

## The commit that took it to zero

`31a6a59`, *"Make the examples easier to read"*, took the score from 36 to 0. The tokens fell too,
to 9739, the cheapest run since 4 August, so anybody watching only the cost would have called it an
improvement. `git show` prints the commit with its diff:

```
ana@lab:~/triage$ git show 31a6a59
commit 31a6a59807c0050e0601d00ab92d82761d8c0dd7
Author: Ana Lima <ana@example.org>
Date:   Fri Aug 14 17:45:00 2026 -0300

    Make the examples easier to read

diff --git a/prompts/triage.txt b/prompts/triage.txt
index 43dc42c..ea04ec1 100644
--- a/prompts/triage.txt
+++ b/prompts/triage.txt
@@ -11,17 +11,17 @@ Read the message and answer in JSON with three fields:
 
 <example>
 Message: I paid for express delivery but the order came by normal post.
-Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back."}
+Output: billing, normal: wants the express delivery charge back
 </example>
 
 <example>
 Message: The book came with water damage on every page.
-Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book."}
+Output: returns, normal: wants a replacement for a damaged book
 </example>
 
 <example>
 Message: Can I change the name on my account?
-Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name."}
+Output: account, low: asks how to change the account name
 </example>
 
 Reply with only the JSON object: no code fence and no other text.
```

The examples stopped being JSON. Each `Output:` became a line of words that a person reads more
easily, and the instruction to reply with only the JSON object stayed where it was. In the stand-in
**the first example's shape beats the description**, as lesson 1 showed with an order number, and
this time it copied everything:

```
ana@lab:~/triage$ git show 31a6a59:prompts/triage.txt > runs/triage-31a6a59.txt
ana@lab:~/triage$ pl run runs/triage-31a6a59.txt cases/dev.jsonl --out runs/31a6a59.jsonl
40 calls, prompt 055cb22b, written to runs/31a6a59.jsonl
ana@lab:~/triage$ pl show runs/31a6a59.jsonl t04
│ account, high: wants the express delivery charge back
stop: end, tokens in 233, out 10
```

`t04` is the customer who cannot log in. The reply has the example's shape, the right category, an
urgency the person would not give, and the first example's summary word for word. Not one of the
forty replies parses as JSON. The change was a reasonable edit made for a reader, and it stayed in
the file from 14 August to 17 August, when `03e1151` put the examples back.
