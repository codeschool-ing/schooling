---
title: A prompt
version: 1
---

The third primitive is the one a **person** chooses. A host shows the server's prompts as something like slash commands; the person picks one and fills in the arguments, and the host puts the resulting messages into the conversation.

```
ana@lab:~/agents$ python try_server.py prompt 2> server.log
prompt: reply_to_customer [('order_id', True), ('question', True)]
user: A customer asks about order M-1042: Can I still return it?
Look the order up with get_order, check the help centre if a policy applies, and draft a short reply. Quote dates and amounts exactly as the tools return them.
```

`reply_to_customer` has two required arguments, and `prompts/get` returned one user message with both filled in. The text tells the model how to work: look the order up, check the help centre, quote dates and amounts exactly.

Two points about it. **A prompt is the server's text entering the conversation**, like a tool description, but this time as a user message, chosen by a person who may not read it first. The same judgement applies: connect servers whose words you would accept in your prompt. And **a prompt is not a permission**. It says *look the order up with get_order*; whether `get_order` may run, and whether a refund would need a person, is still decided by the host when the model asks.
