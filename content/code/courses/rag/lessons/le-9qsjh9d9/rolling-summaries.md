---
title: Rolling summaries
version: 2
---

A long conversation is compacted more than once. The simple way is to summarise the old summary
together with the new turns, every few turns, so that the summary rolls forward with the conversation.
`rolling.py` does that every four turns, with a limit of 40 words:

```schooling-example
{
  "language": "python",
  "file": "rolling.py",
  "parts": [
    {
      "code": "from compact import summarise, tokens\nfrom essentials import ESSENTIALS, TURNS, kept\n\nsummary = \"\"\nfor start in range(0, 12, 4):\n    block = ([summary] if summary else []) + TURNS[start:start + 4]\n    summary = summarise(block, 40)\n    print(f\"after turns {start + 1:2}-{start + 4:2}: {tokens(summary):3} tokens, essentials {len(kept(summary))}/{len(ESSENTIALS)}\")\n    print(\"  \", summary)",
      "note": "The conversation summarised four turns at a time, each summary folded into the next, as a chat that compacts as it goes would do it."
    }
  ]
}
```

```
ana@vm:~/rag$ python rolling.py
after turns  1- 4:  37 tokens, essentials 2/6
   Beatriz Costa, your order MG-20481937 had two issues: one book had water damage and the other was the wrong title, Mansfield Park instead of Middlemarch.
after turns  5- 8:  53 tokens, essentials 1/6
   Beatriz Costa's order had two issues: a water-damaged book and incorrect title. She wants a replacement for Persuasion, but a refund for Middlemarch, which she bought elsewhere. She has photos of the damaged book and wants to send them.
after turns  9-12:  47 tokens, essentials 1/6
   Beatriz Costa's order had two issues: a water-damaged book and incorrect title. She wants a replacement for Persuasion and a refund for Middlemarch, which she bought elsewhere, and has photos of the damaged book.
```

After the first four turns the summary held **two essentials**, the order number and the wrong book.
After the next four, one, and the order number was gone: the second summary was made from the first
summary and four new turns, and the first summary's sentences competed with the new ones for 40 words
and lost. After the last four, still one. The email-only request, said in the fourth turn, never made
it into any of them.

**A rolling summary loses facts it once had.** Each round is a new choice made without knowing what
the earlier choices were for, so a fact that survived one round can be dropped in the next, and it is
then gone for every round after. It is the copy of a copy of a copy, and nothing in the latest summary
shows what was in the first.

Pinning fixes this the same way it fixed the single summary: pinned sentences are carried forward as
they are, and only the unpinned part is summarised each round. The essentials test fixes the rest:
run it on the summary after every round, not only the first, and a fact lost in round three is found
in round three.
