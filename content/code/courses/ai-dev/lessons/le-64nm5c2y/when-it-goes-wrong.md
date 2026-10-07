---
title: When the loop goes wrong
version: 2
---

An agent goes wrong in two directions. It stops too early, answering from what it guessed rather
than from what its tools returned; or it does not stop, asking for the same thing again or exploring
without converging. The model does not notice either, because each step is a fresh decision from a
conversation that looks fine. **The host has to notice**, with guards that do not depend on the
model's judgement.

## Stopping too early

```
ana@dev:~/shop$ python agent.py "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest_lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest_lamp"})
[1] result: Error executing tool read_handbook: 'cheapest_lamp' is not a page of the
[2] model:  It seems that the tool "read_handbook" is not able to provide information on the cheapest lamp. However, I can suggest some options to help you find a affordable lamp.

Our most basic lamp is the "Classic Table Lamp" which is priced at $19.99. It's a simple and functional lamp that can provide adequate lighting for a small space. Please note that prices may vary depending on the location and availability.

If you're looking for something even more affordable, you can consider our "String Lights" which are priced at $9.99. They're a great option for adding some ambiance to a room without breaking the bank.

Please let me know if you have any other questions or if there's anything else I can help you with.
host: 2 requests, 421 input tokens: [285, 136]
```

The model asked for a handbook page called `cheapest_lamp`, which does not exist, and the tool said
so and listed the pages that do. Then it answered anyway: a "Classic Table Lamp" at $19.99 and
"String Lights" at $9.99. **The shop sells neither**, nothing in this conversation mentions either, and the
prices are in dollars for a shop that charges reais. The handbook does not list prices at all, so
the right answer was that the tools could not say. Another run of the same command, while this lesson was
being prepared, called it a "Basic Table Lamp" at the same $19.99, which is how invented facts
behave: the shape stays and the details move.

The host can tell the model what it does not know and what the rule is. `--rules` adds the system
prompt of lesson 7 section 03, today's date and "every fact must come from a tool result":

```
ana@dev:~/shop$ python agent.py --rules "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest lamp"})
[1] result: Error executing tool read_handbook: 'cheapest lamp' is not a page of the
[2] model:  It seems that the tool "read_handbook" couldn't find the information on the cheapest lamp. I couldn't find the answer to your question in the handbook. Can I help you with something else?
host: 2 requests, 509 input tokens: [330, 179]
ana@dev:~/shop$ python agent.py --rules "Can the customer of order 1042 still return it?"
[1] call:   read_handbook({"name": "returns"})
[1] result: # Returns and refunds A customer may return any item within 30 days of d
[2] model:  The customer of order 1042 can still return it within 30 days of delivery. To start a return, the customer needs to open the order in their account and choose "Return an item". The shop will email a prepaid label within one working day. The refund will be processed once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs will be refunded only when the whole order is returned.
host: 2 requests, 635 input tokens: [334, 301]
```

The lamp question now ends where it should: the model could not find it. The return question reads
the returns page this time, and gives the rule, 30 days from delivery, which is true. It still never
looks up the order, so "can still return it" is a conclusion with no delivery date behind it; it
happens to be right, nine days after delivery, and it would have read the same on day forty. **A
system prompt makes invention rarer; it does not make an answer checked.** The check is still a
person, or a program, comparing every fact with a tool result.

## Not stopping

Lesson 7 section 03 found why this model stops so early: after a tool result, Ollama's template for
`llama3.2:3b` shows it no tools. `--remind` adds one sentence of the host's after every batch of
results, *Call another tool if you need one; otherwise answer.*, which makes the last message the
user's again, so the tools are listed again:

```
ana@dev:~/shop$ python agent.py --remind "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest_lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest_lamp"})
[1] result: Error executing tool read_handbook: 'cheapest_lamp' is not a page of the
[2] call:   read_handbook({"name": "products"})
[2] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[3] call:   read_handbook({"name": "products"})
[3] host:   the same call twice in one task; stopping
host: 3 requests, 1193 input tokens: [285, 372, 536]
ana@dev:~/shop$ python agent.py --remind "Can the customer of order 1042 still return it?"
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] call:   issue_refund({"order_id": "1042", "cents": "0"})
allow issue_refund({"order_id": "1042", "cents": "0"})? [y/N] 
[2] result: refused by the operator
[3] call:   issue_refund({"order_id": "1042", "cents": "0"})
[3] host:   the same call twice in one task; stopping
host: 3 requests, 1147 input tokens: [289, 402, 456]
```

**Now it never answers.** With the tools in front of it, the template's instruction, *respond with a
JSON for a function call*, applies on every step, so every step is a call. The lamp question reads
the products page, which has no prices, and asks for it again; the return question looks up the
order and then asks, twice, to refund it, for `"0"` cents, which nobody wanted. **The repeat guard
ends both at step 3**, the approval step had already refused the refund once, and the last line says
what each cost: 1,193 and 1,147 input tokens, each request bigger than the one before because it
carries everything so far. With the tools in sight, the second request is the bigger one, as it
should have been all along.

Neither setting makes this model a working agent on this server: without the reminder it gets one
round of tools, with it it never stops calling them. Two other models of about this size,
`qwen2.5:3b` and `qwen2.5:7b`, were asked the same questions while this lesson was prepared; their
templates keep the tools in sight, and both still answered after one call, with the same wrong
conclusion about order 1042. **The host's guards are what made every one of these failures cheap**,
and they are the part of this lesson that does not depend on the model. A loop of five steps over real tool results, pages of documents or rows of data, adds up
quickly.

## The guards

- **A step limit**, enforced by the loop, with a message that says the task was not finished. Pick it
  from the longest legitimate task, measured.
- **A repeat check** on the same tool with the same arguments.
- **A budget** in tokens or money per task, the guard of lesson 2 section 09 applied to the whole
  loop rather than one request.
- **A time limit**, for tools that can hang.
- **A record of every step**, so a stopped run can be read afterwards and the case added to an
  evaluation (lesson 5 section 09) of tasks the agent should be able to finish.

Most runaway agents in production are not malicious or broken. They are a model doing the likely
next thing, correctly, forever, with nothing in the host to say stop.
