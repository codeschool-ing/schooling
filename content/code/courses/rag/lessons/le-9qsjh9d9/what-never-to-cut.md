---
title: What never to cut
version: 2
---

Compaction applies to sources as well as to conversations: a long document fetched by an agent, an
old source still in a chat's context, a section too long for the budget. Lesson 12 compressed sources
by keeping whole sentences about the question; a summary goes further, and some sentences do not
survive being separated from their neighbours. Two sections of the returns policy, summarised in at
most 25 words:

```schooling-example
{
  "language": "python",
  "file": "policy.py",
  "parts": [
    {
      "code": "import sys\n\nfrom chunking import load, sections\nfrom compact import summarise\n\nmeta, body = load()[\"returns-policy\"]\nfor path, text in sections(body):\n    if path.endswith(sys.argv[1]):\n        print(\" \".join(text.split()))\n        print(\"summary:\")\n        print(summarise([text], int(sys.argv[2])))",
      "note": "One section of the returns policy, and the model's summary of it."
    }
  ]
}
```

```
ana@vm:~/rag$ python policy.py "Items that cannot be returned" 25
The following cannot be returned unless they arrive damaged or faulty: - personalised copies and copies signed by the author; - jigsaw puzzles and games whose packaging has been opened; - anything bought in the clearance section; - newspapers and magazines.
summary:
Certain items, including personalised copies, opened games, clearance purchases, and newspapers, cannot be returned unless damaged or faulty.
```

**The summary kept the rule, the exception and all four kinds of item**, in one sentence, and it did
lose one thing on the way: *copies signed by the author* became *personalised copies*, and a customer
with a signed copy is no longer named by it. A list summarised into a sentence keeps its categories and
drops their members, and the member dropped is the one somebody asks about.

```
ana@vm:~/rag$ python policy.py "Gifts" 25
The person who received a gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return from their own account.
summary:
The person who received a gift can return it with a receipt, getting store credit, while the buyer must initiate the return from their own account.
```

The gift rule kept its two halves, and the second half lost its condition. The policy says the buyer
starts the return *to get the money back on the original card instead*; the summary says the buyer
must start it, full stop, so it reads as a rule about every gift return and it is about the exception.
A sentence that depended on *instead* was rewritten without the word, and its meaning went with it.

From these and the previous sections, the things a compaction must keep or keep together:

- **Identifiers and numbers**: order numbers, amounts, dates, deadlines. They are said once and needed
  exactly.
- **Negations and conditions**: *not*, *unless*, *only*, *except*. Losing one inverts the sentence.
- **References with their referents**: *it*, *them*, *instead*, *the other*. A sentence that points
  backwards is only true next to what it points at.
- **Choices and instructions from the person**: what they asked for and how to reach them.
- **Anything a reply has already cited.** If an answer quoted a source as [2], the compacted context
  must still let [2] be checked, or lesson 7's verification has nothing to verify.
