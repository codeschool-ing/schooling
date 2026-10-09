---
title: Tracking the effect of each change
version: 2
---

With one file, a history and an id that means something, the obvious next step is to run every
version against the same messages. This program does that in one command: for each commit that
touched `prompts/triage.txt`, oldest first, it takes the file as it was, writes it to
`runs/triage-<commit>.txt`, runs it over a test set and prints two numbers. Save it as `log.py`:

```python
"""log: every version of a prompt in git, run over one test set: what it
scored and how many tokens the run took."""
import subprocess
import sys

from pl import DEFAULTS, call, judge, read_jsonl, read_prompt, render, values_of

PATH = "prompts/triage.txt"


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


cases_path = sys.argv[1] if len(sys.argv) > 1 else "cases/dev.jsonl"
cases = read_jsonl(cases_path)
print("commit   date        all tokens  subject")
for line in git("log", "--reverse", "--date=short", "--format=%h %ad %s", "--", PATH).splitlines():
    sha, date, subject = line.split(" ", 2)
    old = "runs/triage-%s.txt" % sha
    with open(old, "w", encoding="utf-8") as f:
        f.write(git("show", "%s:%s" % (sha, PATH)))
    params, template = read_prompt(old)
    params = {**DEFAULTS, **params}
    passed = tokens = 0
    for case in cases:
        row = call(render(template, values_of(case, {})), params)
        passed += judge(row, case["expect"])[0] is None
        tokens += row["tokens_in"] + row["tokens_out"]
    print("%s  %s %2d/%d %6d  %s" % (sha, date, passed, len(cases), tokens, subject))
```

It uses the harness's own `call()`, `render()` and `judge()`, so a pass here is a pass in `pl check`.
Over the forty dev messages:

```
ana@lab:~/triage$ python3 log.py
commit   date        all tokens  subject
341f8f8  2026-08-03  0/40   6692  First triage prompt
61d470e  2026-08-04 22/40   5476  Ask for JSON, name the fields and list the labels
ab97290  2026-08-05 28/40  11152  Add three examples of the answer
5b2d8d0  2026-08-07 26/40  11726  Ask for the JSON object and nothing else
a0f1d2a  2026-08-10 24/40  13408  Put the message in tags and say it is data
c8f1927  2026-08-11 24/40  13408  Escape the message so it cannot close its own tags
86913c0  2026-08-14 27/40  11553  Make the examples easier to read
85dfa4e  2026-08-17 24/40  13408  Put the examples back in JSON
```

`all` is the count of replies that passed every check. `tokens` is everything the forty calls
consumed, input and output added together. Read down the two columns rather than across the rows,
because **the useful thing is how each number moved from the commit above it**.

## The commits that earned their place

`61d470e` took the score from 0 to 22 by asking for JSON, and the tokens went *down*, from 6692 to
5476, because the bare prompt's long, chatty answers were costing more than the field list did.
`ab97290` took the score from 22 to 28 by adding examples, the change lesson 1 measured, and doubled
the tokens to 11152. That is what a change that earned its cost looks like in this table: one number
up, the other up, and a reason to think the first was worth the second.

## The commits that cost tokens and moved the other way

`5b2d8d0`, *"Ask for the JSON object and nothing else"*, added 574 tokens over forty calls and the
score went from 28 to 26. `a0f1d2a`, the tags and the sentence saying the message is data, added
another 1682 and the score went to 24. Two lines each, so lesson 11's warning applies, and it is
worth knowing what they were for before anybody reverts them. **A score that falls on dev does not
mean the change did nothing**; it may mean dev does not test what the change was for. The tags were
about instructions hidden in a message, and the attack set is where those live:

```
ana@lab:~/triage$ python3 log.py cases/attacks.jsonl
commit   date        all tokens  subject
341f8f8  2026-08-03  0/10   1739  First triage prompt
61d470e  2026-08-04  1/10   1545  Ask for JSON, name the fields and list the labels
ab97290  2026-08-05  2/10   2804  Add three examples of the answer
5b2d8d0  2026-08-07  2/10   2982  Ask for the JSON object and nothing else
a0f1d2a  2026-08-10  3/10   3464  Put the message in tags and say it is data
c8f1927  2026-08-11  3/10   3473  Escape the message so it cannot close its own tags
86913c0  2026-08-14  3/10   3052  Make the examples easier to read
85dfa4e  2026-08-17  3/10   3473  Put the examples back in JSON
```

On the ten attacks the tags took the score from 2 to 3, the only commit after the examples to move
it. `c8f1927`, the escaping commit, moves no score on either set: lesson 9 showed what it is for, a
message that would otherwise break the prompt's shape, and neither set has one. **A change no test
set can see is a change you are taking on trust.** Either add the case that shows what it fixes, or
write down that it fixes nothing you can measure.

## The commit that reads like a fix

`86913c0`, *"Make the examples easier to read"*, rewrote the three examples as plain lines and left
the instruction to reply with only a JSON object. That looks reckless: lesson 1 found the examples'
shape is what the model copies. The table says the score went from 24 to 27 and the tokens fell to
11553. Three days later `85dfa4e`, *"Put the examples back in JSON"*, undid it, and the score went
back to 24. `git show` prints the commit that was undone, with its diff:

```
ana@lab:~/triage$ git show 86913c0
commit 86913c05e4fd31c789427c8645c715c4eb13fdae
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

And here is what one of its replies looks like:

```
ana@lab:~/triage$ pl run runs/triage-86913c0.txt cases/dev.jsonl --out runs/86913c0.jsonl
40 calls, prompt 055cb22b, llama3.2:3b, written to runs/86913c0.jsonl
ana@lab:~/triage$ pl show runs/86913c0.jsonl t04
│ {"category": "account", "urgency": "low", "summary": "has trouble logging in and password reset email never arrives"}
stop: stop, tokens in 260, out 29, 4.2 s
```

Valid JSON, the right category, the wrong urgency for a customer who is locked out, and a summary in
the plain lines' style: lower case and no full stop. With `llama3.2:3b` the format came from the
instruction and the field list, and the examples contributed the labels. **The revert reads like a
fix** and its message says what it did, not why. Somebody believed examples must look exactly like
the answer. That belief came from somewhere reasonable, and on this model, on this day, the table
says it cost three messages and 1855 tokens a run. Whether three messages are real is the next
section's question.
