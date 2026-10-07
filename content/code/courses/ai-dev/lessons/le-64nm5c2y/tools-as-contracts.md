---
title: A tool is a contract
version: 2
---

A model decides which tool to call from three things, and all three are text you write: the tool's
**name**, its **description**, and the **schema** of its arguments. Here is how the shop's server
describes its first tool on the wire, cut to the width of the page:

```
ana@dev:~/shop$ ( printf "%s\n" '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"by-hand","version":"0"}}}' '{"jsonrpc":"2.0","method":"notifications/initialized"}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_order","arguments":{"order_id":"1043"}}}'; sleep 2 ) | python mcp_shop.py | cut -c1-160
{"jsonrpc":"2.0","id":1,"result":{"capabilities":{"experimental":{},"prompts":{"listChanged":false},"resources":{"listChanged":false,"subscribe":false},"tools":
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"annotations":{"readOnlyHint":true},"description":"Look up an order by its number: status, dates, lines and shipping
{"jsonrpc":"2.0","id":3,"result":{"content":[{"text":"{\n  \"status\": \"shipped\",\n  \"shipped_on\": \"2026-09-30\",\n  \"tracking\": \"BR123456789\",\n  \"li
```

The second line is the tool list. Behind the cut, `get_order` has a description (*Look up an order
by its number: status, dates, lines and shipping, in cents*) and a schema saying it takes one string,
`order_id`, which is required. **That is all the model knows about the function.** It has never seen
the code, so a description that says less than the code does is a contract the model will break in
good faith.

## Writing tools a model uses well

- **Narrow, with one job each.** `get_order` and `issue_refund`, not `manage_order(action, ...)`. A
  narrow tool is easier to describe, easier to permit (lesson 7 section 08), and easier to test.
- **Say the units and the formats.** "In cents" in the description of `get_order` is what lets the
  model write 79.80 rather than 7980.00 in its answer. Dates, currencies, ids: the description is the
  only place the model learns them.
- **Typed arguments, required where they are required.** The schema is enforced by the server
  (lesson 8 shows the same for function calling), so a missing or mistyped argument is refused before
  your code runs.
- **Results the model can use.** Plain, short, with the field names it was told about. A tool that
  returns a 5,000-line log fills the context and costs the next step's input.
- **Errors that say what to do.** `'../../.env' is not a page of the handbook` tells the model to pick
  a page name; a stack trace tells it nothing and costs tokens.
- **Read-only when it is.** A tool that changes nothing says so in its annotations, and the host can
  then call it without asking (lesson 7 section 08).

The number of tools matters too. Every definition is sent with every request (lesson 2 section 03
counted 128 tokens for one), and a model choosing among forty similar tools chooses worse than one
choosing among five. Give an agent the tools its task needs.
