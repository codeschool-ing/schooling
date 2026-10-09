---
title: What breaks a cache
version: 2
---

**Any change to the beginning of a prompt makes everything after it new.** The cache finds the
longest stored beginning that matches; the first token that differs ends the match, and every token
after it is read again, even where its text did not change. Hosted caches match a beginning too, and
the consequence is the same.

`v17-message-first` was the extreme case, a different beginning on every call. Ordinary edits do
the same thing more quietly:

- One word changed in the guide makes everything from that word on new. The next call reads it all
  again, and only then does the cache hold the new version.
- A new example inserted near the top moves every token after it, so everything after it changes
  even though its text did not.
- A date, a customer's name or a ticket number placed early, *"Today is 14 August. Customer:
  Maria Souza."*, varies per call exactly as the message does, and costs the cache everything after
  it.
- Five idle minutes on Ollama unload the model, and the cache goes with it.

So keep what varies at the end, and change the fixed part deliberately and rarely, knowing that each
change is paid for once, by the first call that reads it.

## The cache should not change the answers

A cache is supposed to change cost and time and nothing else. Lesson 8 showed that on this machine it
is not quite true: three replies to the same prompt at temperature 0, one read from scratch and two
from the cache, and the first differed from the other two after thirty words. **A cached prompt is
computed by a different path through the same arithmetic**, and a near tie can come out the other
way. That is one more reason to measure over a test set rather than trust that a change to caching
changed nothing.

## Reordering is not a cache setting

Moving the message to the front is a bigger change. It changes the text the model reads, so it is a
new prompt, and its answers may differ for reasons that have nothing to do with the cache:

```
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl
runs/static.jsonl        passes 23/40
runs/first.jsonl         passes 18/40
fixed 0, broken 5
broken: t10 t14 t17 t27 t34
sign test on the 5 that changed: p = 0.062
ana@lab:~/triage$ pl compare runs/static.jsonl runs/first.jsonl --answers
40 cases, same answer 30, different answer 10
  t10    other -> delivery
  t14    account -> other
  t16    billing -> other
  t17    delivery -> None
  t18    returns -> delivery
  t25    account -> delivery
  t33    returns -> delivery
  t34    account -> other
  t38    None -> returns
  t39    account -> other
```

Twenty-three against eighteen, none fixed and five broken, p = 0.062. Ten categories changed, and
`t17` and `t38` traded places on format: `t38`, the ebook whose apostrophe breaks the JSON, parsed
with the message first, and `t17` stopped parsing. **The message-first prompt is slower and, on this
set, worse**, and the sign test on five messages stops just short of calling that more than chance.
A reorder made for the cache goes through the gate of lesson 14 like any other change to the text;
here it would have saved nothing and cost five messages.
