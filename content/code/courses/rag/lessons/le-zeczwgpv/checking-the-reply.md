---
title: Checking the reply
version: 2
---

Whatever reached the model, the reply can be checked before anybody sees it, and lesson 7 already
wrote the check. A reply whose sentences are not quoted, or close to, the sources they cite is not
shown:

```schooling-example
{
  "language": "python",
  "file": "checked.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import ask\nfrom listings import LISTINGS, as_sources\nfrom verify import check",
      "note": "Lesson 7's prompt and lesson 7's check."
    },
    {
      "code": "SAFE = \"I can't compare these listings right now. Each listing's page has the seller's full description.\"\nquestion = sys.argv[1]\nsources = as_sources(LISTINGS)\nreply = ask(question, sources)\nverdicts = check(reply, sources)\nprint(\"reply:  \", reply)\nprint(\"checks: \", [v for _, _, v in verdicts])\ngrounded = all(v.startswith((\"quoted\", \"close\")) for _, _, v in verdicts)\nprint(\"shown:  \", reply if grounded else SAFE)",
      "note": "The reply is shown only if every sentence is quoted or close to the source it cites. Anything else, including a reply that cites nothing, is replaced by a safe message that promises nothing."
    }
  ]
}
```

```
ana@vm:~/rag$ python checked.py "Which copy of Emma is for sale, and in what condition?"
reply:   According to source [4], the copy of Emma for sale is in the condition of "acceptable" and has a loose front cover and some underlining in pencil in the first three chapters.
checks:  ['unsupported (0.58)']
shown:   I can't compare these listings right now. Each listing's page has the seller's full description.
```

**The reply was right, and the customer saw the safe message instead.** The model joined the
condition, which is in the listing's header line, to the description, and the sentence it wrote scores
0.58 against the description's sentences, below the 0.75 the check calls close. The check cannot tell
an attack from a paraphrase; it can only tell what is traceable to a listing from what is not. On an
ordinary day that costs a correct answer now and then, and that cost is the price of the layer: on the
day an injection makes the model say something new, the same rule keeps it from the customer.

This layer is strong against injections that make the model say something new: an invented claim, an
instruction to the customer, a link, a word. It is weaker against an injection that makes the model
**choose** among true sentences, say, quote only the flattering half of one listing, because every
sentence it shows is then genuinely in a source. That is why the check is one layer and not the whole
answer, and why the next section keeps untrusted text out of the contexts where a well-chosen true
sentence could do harm.

The safe message is deliberately plain. It does not say that something suspicious happened, which
would tell whoever planted the text that it was noticed, and it does not guess at an answer. It sends
the customer to the listing pages, which show what the sellers wrote and nothing a model made of it.
