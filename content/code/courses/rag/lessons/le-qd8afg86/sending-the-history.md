---
title: Sending the whole history
version: 1
---

The simplest memory is to send everything again. Chat APIs are built for it: a request carries a list
of messages, and an application that keeps the conversation can put every earlier message back in
front of the new one.

```schooling-example
{
  "language": "python",
  "file": "chat.py",
  "parts": [
    {
      "code": "def ask(sources, question, past=()):\n    messages = [{\"role\": \"system\", \"content\": SYSTEM}, *past,\n                {\"role\": \"user\", \"content\": f\"{numbered(sources)}\\n\\nQuestion: {question}\"}]\n    return (*call(messages), sources)",
      "note": "Lesson 7's prompt, with room for earlier messages between the instructions and the new question."
    },
    {
      "code": "def history(text, past, account, name):\n    \"\"\"Every earlier turn, the customer's and the assistant's, sent again as messages.\"\"\"\n    return ask(sources_for(text), text, past)",
      "note": "The whole conversation so far, the customer's turns and the assistant's replies, goes in again on every turn. The search still sees only this turn."
    }
  ]
}
```

```
ana@lab:~/rag$ python chat.py chat-a history
 1    98 tokens
 2   220 tokens
 3   211 tokens
 4   242 tokens
 5   271 tokens
 6   305 tokens
 7   407 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1] If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. [1]
 8   440 tokens
 9   598 tokens  Do I need to send the damaged copy back to you?
   first document: 0.618  If a book arrives with a torn cover, bent ...
   We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
10   504 tokens  How do I send back Mansfield Park?
   no document above the floor
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park.
11   725 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   For Middlemarch I want my money back. We refund within three working days of the return reaching our warehouse. [1]
12   588 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   I could not find that in our documents.
4609 prompt tokens over 12 turns
```

**The prompt grows with every turn**, from 98 tokens at the first message to 725 at the eleventh, and
the conversation cost 4,609 tokens of prompt where answering each turn alone cost 820. Every turn
pays again for all the turns before it, so a conversation twice as long costs about four times as
much. Lesson 12's budget is gone by the tenth message of a long chat.

And it did not answer the two questions. Turn 10's reply is **"The other parcel had the wrong book: I
ordered Middlemarch and got Mansfield Park."**, Beatriz's own sentence read back to her, with no
citation: extract-1 reads earlier turns as sources without numbers and, with no document above the
floor, the closest sentence it had was hers. Lesson 7's citation check would mark it uncited. Turn 12
was refused even with turn 1 in the prompt, because the search still saw only turn 12 and found no
document, and the sentence holding the order number was not close enough to the question for
extract-1. A language model would read the history differently from this stand-in; what does not
change with the model is that **the search sees only the current message**. History in the prompt
does nothing for the retrieval half.
