---
title: Rolling summaries
version: 1
---

A long conversation is compacted more than once. The simple way is to summarise the old summary
together with the new turns, every few turns, so that the summary rolls forward with the conversation.
`rolling.py` does that every four turns, with a limit of 40 words:

```
ana@lab:~/rag$ python rolling.py
after turns  1- 4:  54 tokens, essentials 3/6
   Hi, my name is Beatriz Costa and I have a problem with order MG-20481937. The order had two books. The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. Please write to me by email only.
after turns  5- 8:  48 tokens, essentials 2/6
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. Where do I send them?
after turns  9-12:  51 tokens, essentials 2/6
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. How do I send back Mansfield Park?
```

After the first four turns the summary held **three essentials**, the order number and the email-only
request among them. After the next four, two, and those two were gone: the second summary was made
from the first summary and four new turns, and the first summary's sentences competed with the new
ones for 40 words and lost. After the last four, still two, and the same two.

**A rolling summary loses facts it once had.** Each round is a new choice made without knowing what
the earlier choices were for, so a fact that survived one round can be dropped in the next, and it is
then gone for every round after. It is the copy of a copy of a copy, and nothing in the latest summary
shows what was in the first.

Pinning fixes this the same way it fixed the single summary: pinned sentences are carried forward as
they are, and only the unpinned part is summarised each round. The essentials test fixes the rest:
run it on the summary after every round, not only the first, and a fact lost in round three is found
in round three.
