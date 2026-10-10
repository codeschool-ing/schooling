---
title: A description is a prompt
version: 2
---

The description is the only explanation the model gets, and it is read at the moment of choosing. **Writing it is prompt engineering**, with the difference that a bad one does not produce a bad paragraph; it produces a wrong call, or no call where one was needed.

Compare the two descriptions of `get_order` this course has used:

| | description |
|---|---|
| lesson 1 | Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents. |
| this lesson | Look up one Marginalia order by its id, which is M- followed by four digits, such as M-1042. Returns status, dates, lines and amounts in cents. |

Both say what the tool does and what comes back. The second also states the id's format in words, which the schema enforces with a pattern. **Saying it in the description prevents the mistake; enforcing it in the schema catches it when the description was not enough.** Section 05 shows both halves: `llama3.2:3b`, told the format, turned the customer's `1043` into `M-1043` by itself, and a stand-in written to ignore the description runs into the pattern instead.

## What a good description says

- **What the tool does, in one sentence a new colleague would understand.** "Look up one order" rather than "Order retrieval endpoint".
- **When to use it, and when not**, if another tool is close. A shop with both `find_books` and a full-text `search_catalogue` should say which one answers "do you have mysteries in stock?".
- **What the arguments mean**, beyond their types: the format of an id, the unit of an amount, whether a date is inclusive.
- **What comes back**, including units. `find_books` says "prices in cents"; without it, 3190 reads as a price nobody pays for a paperback.
- **What it changes, if anything.** `issue_refund` says it refunds, and says what a repeated key does. A tool with a side effect that its description does not mention is a trap for the model and for whoever reviews the trace.

## What it should not say

Instructions that belong to the host. *"Only call this after confirming with the customer"* in a description is a request the model may or may not honour; if it matters, the host enforces it (lesson 17). And nothing secret: descriptions go to the provider with every request and appear in traces, so an internal URL or a key in one has been published.

**Descriptions are also an attack surface when someone else writes them.** A tool handed over by a third party, as MCP servers do (lessons 11 to 16), arrives with its own description, and a description is text the model reads as guidance. Lesson 16 is about reading those before trusting them.
