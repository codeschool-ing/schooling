---
title: Talking to the server from Python
version: 1
---

The host of lesson 7 section 03 and every assistant that supports MCP do the same three things as a
client: start or connect to the server, list its tools, call them. The SDK's `Client` does the
handshake of lesson 7 section 05 for you:

```python
import asyncio
import sys

from mcp import Client, StdioServerParameters


async def main():
    async with Client(StdioServerParameters(command="python", args=["mcp_shop.py"])) as shop:
        if len(sys.argv) < 3:
            for t in (await shop.list_tools()).tools:
                ro = t.annotations.read_only_hint if t.annotations else None
                print(f"{t.name:14} read-only={ro!s:5}  {t.description}")
        else:
            result = await shop.call_tool(sys.argv[1], {"name": sys.argv[2]})
            print("is_error:", result.is_error, "|", result.content[0].text[:90])


asyncio.run(main())
```

```
ana@dev:~/shop$ python lab/tools.py
get_order      read-only=True   Look up an order by its number: status, dates, lines and shipping, in cents.
read_handbook  read-only=True   Read one page of the support handbook, such as 'returns' or 'shipping'.
issue_refund   read-only=False  Refund part or all of an order to the customer's original payment method.
```

Three tools, and the annotation that matters most for the next section: two say they only read, one
says it does not. The host reads `read_only_hint` from here and decides which calls need a person.

## A hint is not a guarantee

`readOnlyHint` is the **server's own description of itself**. A server you wrote, like this one, can
be trusted to describe itself correctly, because you can read it. A server from somewhere else is
different: a careless or hostile one can call a tool read-only and have it do anything. The MCP
specification says as much, and treats annotations as hints a host should not rely on for safety
unless it trusts the server.

So the question before installing a server is the same as before installing any program: who wrote
it, what can it reach, and do you trust both answers. The permissions in lesson 7 section 08 are
written against that question.
