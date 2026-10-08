#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# THE MODEL'S DECISIONS COME FROM llama3.2:3b AT TEMPERATURE 0, through agent.py:
# which tool it calls, with which arguments, and what it says at the end. A rerun
# mostly takes the same path and not always; the invented lamps of
# when-it-goes-wrong changed their names between two runs. The MCP server and
# client (the mcp SDK), the loop, its guards and the approval step are real, and
# so are the tool results. An approval prompt reads stdin: `echo n` and `echo y`
# answer it, and a command with nothing piped in has its stdin closed, which the
# host reads as a no.
#
# Before this was recorded, qwen2.5:3b and qwen2.5:7b were asked the same questions, to see
# whether the lesson needed a bigger model for an agent that chains its tools:
# neither chained them either, so the lesson stays on llama3.2:3b.
#
#   model    llama3.2:3b (a80c4f17acd5), Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, the handbook of lesson 6 (its script, run), and the files
# ana wrote (put below), each of which a lesson shows whole; put refuses one
# that no lesson shows byte for byte.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab reset
put scratch/make-handbook.sh <<'SH'
# make-handbook.sh: the shop's support handbook, eight files in docs/handbook
mkdir -p docs/handbook
cat > docs/handbook/returns.md <<'EOF'
# Returns and refunds

A customer may return any item within 30 days of delivery, for any reason. The
item must be unused and in its original packaging. Mugs and glasses must also
be unbroken; a breakage in transit is a damaged delivery, not a return.

To start a return, the customer opens the order in their account and chooses
"Return an item". The shop emails a prepaid label within one working day.

The refund goes back to the original payment method once the item arrives at
the warehouse and is checked, which takes up to five working days. Shipping
costs are refunded only when the whole order is returned.

After 30 days the shop does not accept returns, but a faulty item is covered
by the warranty described in warranty.md.
EOF
cat > docs/handbook/shipping.md <<'EOF'
# Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
inside Brazil takes three to eight working days depending on the region.

Shipping costs a flat 15.00 per order. It is free when the order total after
any coupon is 200.00 or more; the threshold is checked after the discount, so a
coupon can bring an order back under it.

The shop ships only to addresses in Brazil. It does not ship abroad and does
not deliver to post office boxes.

A customer can follow the parcel with the tracking code in the shipping email.
A parcel with no tracking update for ten working days is reported as lost.
EOF
cat > docs/handbook/coupons.md <<'EOF'
# Coupons

Two coupons are active. WELCOME10 takes 10% off and has no end date.
FRIENDS15 takes 15% off and is valid until 31 October 2026, inclusive.

Only one coupon applies per order; entering a second one replaces the first.
Codes may be typed in any case. A coupon cannot be applied after the order is
placed, and it is never exchanged for cash.

The discount is taken from the items, not from shipping, and is rounded down
to a whole cent.
EOF
cat > docs/handbook/payment-errors.md <<'EOF'
# Payment errors at checkout

The checkout shows a code when a payment fails. Read the code before anything
else; most failures are on the card issuer's side.

E1001: the card was declined by the issuer. Ask the customer to contact their
bank or use another card. The shop cannot see the reason.

E1042: the payment timed out between the shop and the payment service. No
money was taken. The customer can simply try again after a minute; if it
happens three times in a row, escalate to the on-call developer.

E2003: the billing address does not match the card. The customer should check
the postcode, which is the usual mistake.
EOF
cat > docs/handbook/warranty.md <<'EOF'
# Warranty

Every item has a 90-day warranty against manufacturing faults, counted from
delivery. A fault is something that stops the item working as described: a
lamp that does not light, a handle that comes off a mug in normal use.

Damage from a fall, from a dishwasher on a product marked hand-wash only, or
from ordinary wear is not covered.

Under warranty the shop replaces the item, or refunds it if it is out of
stock. The customer sends a photo of the fault from their account; there is
no need to send the item back unless the shop asks for it.
EOF
cat > docs/handbook/account.md <<'EOF'
# Accounts and passwords

A customer can check out without an account, but needs one to follow orders,
start a return or use the warranty.

To reset a password, the customer chooses "Forgot password" on the sign-in
page and follows the link in the email, which is valid for one hour. Support
staff never ask for a password and cannot see one.

To close an account, the customer writes to support from the account's email
address. Orders from the last five years are kept for tax reasons; everything
else is deleted within 30 days.
EOF
cat > docs/handbook/contact.md <<'EOF'
# Contacting support

Support answers by email and chat from 9:00 to 18:00, Monday to Friday,
Brasília time, except public holidays. Messages that arrive outside those hours
are answered the next working day, in the order they arrived.

The target for a first reply is four working hours. Anything about a payment
taken twice, or a parcel reported as lost, goes to the front of the queue.
EOF
cat > docs/handbook/products.md <<'EOF'
# Products

The shop sells mugs, glasses, lamps and small furniture. Mugs and glasses are
ceramic or tempered glass; all mugs are dishwasher-safe except the hand-painted
line, which is marked hand-wash only on the box and on the product page.

Lamps take a standard E27 bulb, not included. Furniture arrives flat-packed,
with tools, and the instructions are also on the product page.

Prices on the site include taxes. A price shown in an email or an advert is
valid only if it is also the price on the product page at checkout.
EOF
SH
quiet lab exec ana 'bash scratch/make-handbook.sh'
put data/orders.json <<'JSON'
{
  "1042": {"status": "delivered", "delivered_on": "2026-09-28",
           "lines": [{"sku": "MUG-01", "quantity": 2, "unit_price": 3990}], "shipping": 1500},
  "1043": {"status": "shipped", "shipped_on": "2026-09-30", "tracking": "BR123456789",
           "lines": [{"sku": "LAMP-02", "quantity": 1, "unit_price": 21000}], "shipping": 0}
}
JSON
put mcp_shop.py <<'PY'
"""An MCP server that gives a model three tools over the shop: two that read, one that pays."""
import json
from pathlib import Path

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp.types import ToolAnnotations

HANDBOOK = Path("docs/handbook").resolve()
app = MCPServer("shop")


@app.tool(annotations=ToolAnnotations(readOnlyHint=True))
def get_order(order_id: str) -> dict:
    """Look up an order by its number: status, dates, lines and shipping, in cents."""
    orders = json.loads(Path("data/orders.json").read_text())
    if order_id not in orders:
        raise ToolError(f"no order {order_id}")
    return orders[order_id]


@app.tool(annotations=ToolAnnotations(readOnlyHint=True))
def read_handbook(name: str) -> str:
    """Read one page of the support handbook, such as 'returns' or 'shipping'."""
    path = (HANDBOOK / f"{name}.md").resolve()
    if path.parent != HANDBOOK or not path.exists():
        pages = ", ".join(sorted(p.stem for p in HANDBOOK.glob("*.md")))
        raise ToolError(f"{name!r} is not a page of the handbook; the pages are: {pages}")
    return path.read_text()


@app.tool(annotations=ToolAnnotations(readOnlyHint=False, destructiveHint=True))
def issue_refund(order_id: str, cents: int) -> str:
    """Refund part or all of an order to the customer's original payment method."""
    with open("data/refunds.log", "a") as log:
        log.write(f"{order_id} {cents}\n")
    return f"refunded {cents} cents on order {order_id}"


if __name__ == "__main__":
    app.run()
PY
put agent.py <<'PY'
"""A host: it starts the shop's MCP server, offers its tools to the model, and runs the loop."""
import asyncio
import json
import sys
from datetime import date

import anthropic
from mcp import Client, StdioServerParameters

MAX_STEPS = 5
RULES = (f"Today is {date.today():%d %B %Y}. Answer questions about the shop with its tools. "
         "Every fact in your answer must come from a tool result; if the tools cannot give "
         "the answer, say that you could not find it.")
REMIND = "Call another tool if you need one; otherwise answer."
model = anthropic.Anthropic()
sent = []  # input tokens of each request, reused prefix included (lesson 2 section 07)


def approve(name, args):
    try:
        answer = input(f"allow {name}({json.dumps(args)})? [y/N] ")
    except EOFError:  # nobody at the keyboard is a no
        answer = ""
    print(answer)
    return answer.strip().lower() == "y"


async def run(question, rules, remind):
    async with Client(StdioServerParameters(command="python", args=["mcp_shop.py"])) as shop:
        listed = (await shop.list_tools()).tools
        tools = [{"name": t.name, "description": t.description, "input_schema": t.input_schema} for t in listed]
        read_only = {t.name for t in listed if t.annotations and t.annotations.read_only_hint}
        messages = [{"role": "user", "content": question}]
        extra = {"system": RULES} if rules else {}
        seen = set()
        for step in range(1, MAX_STEPS + 1):
            r = model.messages.create(model="llama3.2:3b", max_tokens=500, tools=tools, messages=messages,
                                      extra_body={"temperature": 0}, **extra)
            sent.append(r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0))
            messages.append({"role": "assistant", "content": [b.model_dump(exclude_none=True) for b in r.content]})
            for b in r.content:
                if b.type == "text":
                    print(f"[{step}] model:  {b.text}")
            if r.stop_reason != "tool_use":
                return
            results = []
            for b in r.content:
                if b.type != "tool_use":
                    continue
                print(f"[{step}] call:   {b.name}({json.dumps(b.input)})")
                call = (b.name, json.dumps(b.input, sort_keys=True))
                if call in seen:
                    print(f"[{step}] host:   the same call twice in one task; stopping")
                    return
                seen.add(call)
                if b.name not in read_only and not approve(b.name, b.input):
                    text, error = "refused by the operator", True
                else:
                    result = await shop.call_tool(b.name, b.input)
                    text, error = result.content[0].text, result.is_error
                print(f"[{step}] result: {' '.join(text.split())[:72]}")
                results.append({"type": "tool_result", "tool_use_id": b.id, "content": text, "is_error": error})
            if remind:
                results.append({"type": "text", "text": REMIND})
            messages.append({"role": "user", "content": results})
        print(f"host: stopped after {MAX_STEPS} steps without an answer")


question = [a for a in sys.argv[1:] if not a.startswith("--")][0]
asyncio.run(run(question, "--rules" in sys.argv, "--remind" in sys.argv))
print(f"host: {len(sent)} requests, {sum(sent)} input tokens: {sent}")
PY
put scratch/tools.py <<'PY'
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
PY

block mcp-by-hand
on '( printf "%s\n" '"'"'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"by-hand","version":"0"}}}'"'"' '"'"'{"jsonrpc":"2.0","method":"notifications/initialized"}'"'"' '"'"'{"jsonrpc":"2.0","id":2,"method":"tools/list"}'"'"' '"'"'{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_order","arguments":{"order_id":"1043"}}}'"'"'; sleep 2 ) | python mcp_shop.py | cut -c1-160'

block a-loop-in-code
on 'python agent.py "Can the customer of order 1042 still return it?"'
on 'ollama show llama3.2:3b --template | sed -n 13,25p'
on 'python agent.py "Look up order 1042 and the returns page of the handbook, then tell me whether the customer can still return it."'

block talking-to-it
on 'python scratch/tools.py'

block permissions
on 'python scratch/tools.py read_handbook shipping'
on 'python scratch/tools.py read_handbook ../../.env'
on 'echo n | python agent.py "Refund order 1042, the customer changed their mind."'
on 'cat data/refunds.log'
on 'echo y | python agent.py "Refund order 1042, the customer changed their mind."'
on 'cat data/refunds.log'

block when-it-goes-wrong
on 'python agent.py "Which is the cheapest lamp you sell?"'
on 'python agent.py --rules "Which is the cheapest lamp you sell?"'
on 'python agent.py --rules "Can the customer of order 1042 still return it?"'
on 'python agent.py --remind "Which is the cheapest lamp you sell?"'
on 'python agent.py --remind "Can the customer of order 1042 still return it?"'
