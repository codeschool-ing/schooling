---
title: What never to cut
version: 1
---

Compaction applies to sources as well as to conversations: a long document fetched by an agent, an
old source still in a chat's context, a section too long for the budget. Lesson 12 compressed sources
by keeping whole sentences about the question; a summary goes further, and some sentences do not
survive being separated from their neighbours. Two sections of the returns policy, summarised in at
most 25 words:

```
ana@lab:~/rag$ python policy.py "Items that cannot be returned" 25
The following cannot be returned unless they arrive damaged or faulty: - personalised copies and copies signed by the author; - jigsaw puzzles and games whose packaging has been opened; - anything bought in the clearance section; - newspapers and magazines.
summary:
jigsaw puzzles and games whose packaging has been opened; anything bought in the clearance section; newspapers and magazines.
```

**The summary is a list of three kinds of item, and nothing says what the list is.** The opening
sentence, "The following cannot be returned unless they arrive damaged or faulty", did not make the
cut, and with it went both the rule and its exception. The first item,
personalised and signed copies, went too. A reader of the summary has three things and no idea whether
they can or cannot be returned.

```
ana@lab:~/rag$ python policy.py "Gifts" 25
The person who received a gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return from their own account.
summary:
To get the money back on the original card instead, the buyer has to start the return from their own account.
```

"Instead" of what? The sentence it depended on, that the person who received the gift gets store
credit, is not there, so the summary reads as a complete instruction about refunds and is about the
exception.

From these and the previous sections, the things a compaction must keep or keep together:

- **Identifiers and numbers**: order numbers, amounts, dates, deadlines. They are said once and needed
  exactly.
- **Negations and conditions**: *not*, *unless*, *only*, *except*. Losing one inverts the sentence.
- **References with their referents**: *it*, *them*, *instead*, *the other*. A sentence that points
  backwards is only true next to what it points at.
- **Choices and instructions from the person**: what they asked for and how to reach them.
- **Anything a reply has already cited.** If an answer quoted a source as [2], the compacted context
  must still let [2] be checked, or lesson 7's verification has nothing to verify.
