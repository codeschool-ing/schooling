---
title: One friendly sentence, and the replies it broke
version: 1
---

Somebody on the support team finds the assistant cold and adds a line to its prompt asking it to
greet clients warmly. It is a reasonable wish, typed directly into the file:

```
ana@lab:~/guard$ echo "Always greet the client warmly and thank them for their patience." >> data/prompts/classify.txt
ana@lab:~/guard$ guard prompts status; echo "exit status $?"
data/prompts/classify.txt    06390ce0eb  NOT APPROVED
data/helpdesk/hc-fees.md     ff40a81202  approved by ana.lima on 2026-10-01
data/helpdesk/hc-payouts.md  0fe2b8eec1  approved by ana.lima on 2026-10-01
data/helpdesk/hc-refunds.md  f32fa16253  approved by ana.lima on 2026-10-01
data/model.json              3138932013  approved by ana.lima on 2026-10-01
exit status 1
```

`status` sees it at once: the prompt is at a version nobody approved, and the exit status is 1
again. In the build, that is a pull request that cannot merge until somebody reviews the change. On a
server where somebody edited the file by hand, it is the check that tells the team the running
assistant is not the one they approved.

What the change does is a measurement, not an opinion. The same twelve tickets:

```
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version 06390ce0eb, model llama3.2:3b: 9 of 12 right, missed t5, t6, t8
ana@lab:~/guard$ guard route data/tickets.jsonl
prompt version 06390ce0eb, model llama3.2:3b: 9 of 12 right, missed t5, t6, t8
```

**Nine right instead of ten**, twice, from one sentence nobody meant to touch classification, and the
list of misses says which ticket it cost: `t6` is new. The new version is in every log line of those
runs, so the replies can be told apart afterwards. The program that reads the log back is short. Save it as `~/guard/tools/trace.py`:

```python
# trace.py: which prompt, which version and which model produced a reply.
#
#   guard trace CALL
#
# It finds the call in data/prompt-log.jsonl and prints what produced it, and
# whether that version of the prompt was ever approved, and by whom.
import argparse
import json
import os

from prompts import approved, load

p = argparse.ArgumentParser(prog="guard trace")
p.add_argument("call")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prompt-log.jsonl"), encoding="utf-8") as f:
    line = next((r for r in map(json.loads, f) if r["call"] == a.call), None)
if line is None:
    p.exit(1, "trace: no call %s in the log\n" % a.call)
e = approved(load(), line["prompt"], line["version"])
print("call     %s (ticket %s)" % (line["call"], line["ticket"]))
print("prompt   %s, version %s" % (line["prompt"], line["version"]))
print("model    %s" % line["model"])
print("approved %s" % ("by %s on %s: %s" % (e["by"], e["on"], e["reason"]) if e else "NEVER"))
print("reply    %s" % line["reply"].replace("\n", " / ")[:70])
```

```
ana@lab:~/guard$ guard trace c18
call     c18 (ticket t6)
prompt   data/prompts/classify.txt, version aa32449d3f
model    llama3.2:3b
approved by ana.lima on 2026-10-01: reviewed, tickets measured
reply    {"category": "account"}
ana@lab:~/guard$ guard trace c30
call     c30 (ticket t6)
prompt   data/prompts/classify.txt, version 06390ce0eb
model    llama3.2:3b
approved NEVER
reply    Dear client, I must say, / Your patience is appreciated each day. / A 
```

`c18` and `c30` are the same ticket, `t6`, before and after the edit. Before, the reply is the JSON the
code reads, from a prompt `ana.lima` approved on 1 October. After, the model wrote a poem, greeting
the client warmly as asked, from a version **approved by nobody**. Without the version in the log,
the poem would be a mystery in the call log: the same assistant, the same model, a different reply,
and nothing to say why. With it, `T10` of lesson 13 has its control. A complaint about any reply is
traced to the exact prompt and model that produced it, and to the person who approved them.

## Why a small model makes the point loudly

A larger model might have greeted the client inside a valid JSON object, or ignored the greeting. It
would still have been a different program, and the twelve tickets are what would show how different.
**The prompt's effect on the output is not readable from the prompt**; it is measured, on the cases
that matter, every time the prompt changes. Lesson 23 turns this run into a test the build performs on
every pull request that touches a file under review.
