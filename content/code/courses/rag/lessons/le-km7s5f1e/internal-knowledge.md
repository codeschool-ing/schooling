---
title: Internal knowledge bases
version: 2
---

The fourth use is the one companies ask for first and deploy last: an assistant over everything the
company has written for itself. The support handbook, the warehouse runbook, the finance procedures,
the minutes of every meeting. The value is obvious, because the knowledge exists and nobody can find
it. The difficulty is that **internal documents were written for particular readers**, and an
assistant that reads all of them on behalf of anybody has quietly removed a boundary the documents
relied on.

## Who each document is for

Every document in this corpus says who it was written for, in its front matter:

```
ana@vm:~/rag$ grep -h "^audience:" data/docs/*.md | sort | uniq -c
      1 audience: developers
      1 audience: finance
      8 audience: public
      1 audience: sellers
      2 audience: staff
```

Eight are public: anybody may read the returns policy. Two are for staff, one for marketplace
sellers, one for developers with an affiliate key, and one only for the finance team. The finance
document says so in its first paragraph: *do not share the thresholds in this document with support
agents, sellers or customers: an agent who knows them can be talked into working around them.*

Now ask the search from a support agent's desk:

```
ana@vm:~/rag$ python sections.py "When does an order get held for manual fraud review?"
[1] 0.720  finance-refund-controls > Automatic holds
[2] 0.573  support-handbook > Suspected fraud
[3] 0.514  finance-refund-controls > Finance reviews
According to [1] finance-refund-controls > Automatic holds, an order gets held for manual fraud review when its fraud score is 0.82 or more.
```

**The exact threshold the finance team asked to keep from support agents, delivered to a support
agent, with a citation.** Nothing went wrong in the pipeline. The question was a good question, the
search found the best section, the generator answered from it faithfully. The leak is a property of the
design: one index over documents with different readers, and a search that does not know who is
asking.

The right section for this agent was the second one, the handbook's *Suspected fraud*, which says to
open a finance review and keep answering the customer normally. It came second because it is about
what to *do*, and the question was about the rule.

## Why this cannot be fixed in the prompt

The tempting fix is an instruction: *do not reveal confidential information.* It fails for a reason
worth stating plainly. **Once the text is in the prompt, it has been disclosed to the model**, and
the only thing between it and the reader is the model's judgement about an instruction. A model can
be argued out of an instruction; a question can be phrased so that the threshold is quoted as part of
"explaining the process"; and the model cannot tell which reader is entitled to what, because nothing
in the request says who the reader is.

The only reliable place for the boundary is **before retrieval**: the search returns only chunks the
asker may read, decided from who they are, not from what they asked. That needs the audience stored
beside every chunk, which lesson 5 does, and a filter built from the signed-in user's role, which is
lesson 14. Until then, the honest arrangement is two indexes, one public and one per audience, and
this lesson's runs show why one index for everything is not a shortcut.

## What internal knowledge asks of a pipeline

- **Permissions on every chunk**, copied from the document at indexing time and enforced at search
  time.
- **An owner for every document.** The `owner:` line in the front matter says who keeps each one
  true; an internal knowledge base rots fastest because nobody's job is to keep it current.
- **Deletion that works.** When a document is withdrawn, its chunks must leave the index the same
  day, not at the next full rebuild.
- **A record of what was asked and what was retrieved**, so that a leak like the one above is found
  in a log rather than in a screenshot. Lesson 9 logs every query.
