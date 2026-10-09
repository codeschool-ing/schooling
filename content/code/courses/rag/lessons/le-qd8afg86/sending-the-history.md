---
title: Sending the whole history
version: 2
---

The simplest memory is to send everything again. Chat APIs are built for it: a request carries a list
of messages, and an application that keeps the conversation can put every earlier message back in
front of the new one.

```schooling-example
{
  "language": "python",
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
ana@vm:~/rag$ python chat.py chat-a history
 1   119 tokens
 2   299 tokens
 3   358 tokens
 4   393 tokens
 5   426 tokens
 6   577 tokens
 7   684 tokens  I have photographs of the damaged cover next to the box. Where do I send them?
   first document: 0.563  If a book arrives with a torn cover, bent ...
   According to our returns and refunds policy [1], you can send the photographs of the damaged cover next to the packaging to our customer service email address. Please reply to this email with the photos, and we will process a replacement for Persuasion.

Regarding the incorrect book, Middlemarch, I will need to escalate this issue to our customer service team. They will contact you to discuss a refund or replacement options.
 8   734 tokens
 9  1025 tokens  Do I need to send the damaged copy back to you?
   first document: 0.617  If a book arrives with a torn cover, bent ...
   According to our returns and refunds policy [1], you do not need to send the damaged copy of Persuasion back to us. We will replace it at no cost.

However, I must correct my previous response regarding the shipping address. Since you are moving house, we will need to update your address with our system. Please allow a few extra days for the replacement to be processed and shipped to your new address.

I will also make a note to contact you regarding the incorrect book, Middlemarch, as soon as possible.
10  1019 tokens  How do I send back Mansfield Park?
   no document above the floor
   I could not find that in our documents.
11  1235 tokens  How long will the refund for Middlemarch take?
   first document: 0.611  We refund within three working days of the return ...
   According to our returns and refunds policy [1], [2], and [3], since you are returning the incorrect book, Middlemarch, within 14 days of receiving it, we will send the correct book immediately with a prepaid label for the wrong one. You will not be charged twice.

As for the refund, it will be processed within three working days of the return reaching our warehouse. Since you are returning the book within the 14-day timeframe, the refund should be processed within the next 3 working days.

Please allow 15-20 working days for the refund to be processed and reflected in your account.
12  1201 tokens  Sorry, what was my order number again? I need it for my notes.
   no document above the floor
   Your order number is MG-20481937.
8070 prompt tokens over 12 turns
```

**The prompt grows with every turn**, from 119 tokens at the first message to 1,235 at the eleventh,
and the conversation cost 8,070 tokens of prompt where answering each turn alone cost 908. Every turn
pays again for all the turns before it, and for the assistant's replies to them, so a conversation
twice as long costs about four times as much. Lesson 12's budget is gone by the tenth message of a
long chat.

**It answered turn 12**: *Your order number is MG-20481937*, read from turn 1, which was in the
prompt. That is what sending the history is for, and it is the only one of the three questions that
needed the past that it answered. Turn 10 was refused, because the search still saw only turn 10 and
found no document; **history in the prompt does nothing for the retrieval half**. And the replies
grew with the history. Turn 9's reply corrects a shipping address nobody asked about, and turn 11's
answers the refund with the right three working days and then *Please allow 15-20 working days*, a
number no source contains. The model's own earlier replies are in the prompt too, and a small model
reading a long conversation keeps adding to it.
