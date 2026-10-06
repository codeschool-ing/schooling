---
title: A conversation is not a question
version: 1
---

Every pipeline in this course so far has answered one question at a time. A support chat is not
that. It is one customer telling a story over several messages, and the later messages lean on the
earlier ones: "the other parcel", "it", "my order number again". `data/chat-a.jsonl` is twelve
messages from Beatriz Costa about order MG-20481937, written for the course: a damaged copy of
*Persuasion*, the wrong book instead of *Middlemarch*, a request to be contacted by email only, and
four questions near the end.

`chat.py` plays the conversation turn by turn with a choice of memory. The first is none: each
message goes through lesson 7's pipeline as if it were the only one.

```
ana@lab:~/rag$ python chat.py chat-a alone
 1     0 tokens
 2   163 tokens
 3     0 tokens
 4     0 tokens
 5     0 tokens
 6     0 tokens
 7   164 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1]
 8     0 tokens
 9   220 tokens  Do I need to send the damaged copy back to you?
   first document: 0.618  If a book arrives with a torn cover, bent ...
   We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
10     0 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11   273 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   We refund within three working days of the return reaching our warehouse. [1]
12     0 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
820 prompt tokens over 12 turns
```

For each turn, the tokens the prompt cost (0 when the floor refused without calling the model), and
for each question, the first document the search found and the reply. **Three of the five questions
work alone**, because they carry their own subject: damaged covers, a damaged copy, a refund. Two do
not.

- **Turn 10, "How do I send back Mansfield Park?"**, finds nothing above the floor. *Mansfield Park*
  is a title, and no policy mentions it; what makes the question answerable is turn 3, where
  Beatriz said it was the wrong book.
- **Turn 12, "what was my order number again?"**, finds nothing, because the answer is not in any
  document. It is in turn 1.

Both refusals are correct by lesson 7's rule, and both would make a customer close the chat: the
assistant has been told everything it needs, and behaves as if it had heard nothing. The rest of the
lesson is three ways of giving it a memory, and what each costs.
