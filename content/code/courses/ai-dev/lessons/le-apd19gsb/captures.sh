#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full, and a commit of shop_tools.py and
# retry.py before the change to them, so that git diff can show the change.
#
# THE MODEL'S REPLIES IN THIS LESSON WERE WRITTEN BY THE COURSE. Which tool
# scripted-1 calls, with which arguments (the wrong ones included), and the
# JSON it returns for an email are rules in lab/scripted.json. The SDKs, the
# schema checks, the shop's own rules and every error message are real. The
# emails, the stock and the orders were written for the course.
#
# The shop's "today" is fixed at 2 October 2026 in shop_tools.py, so the
# 30-day return window gives the same answer on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

put data/orders.json <<'JSON'
{
  "1042": {"status": "delivered", "delivered_on": "2026-09-28",
           "lines": [{"sku": "MUG-01", "quantity": 2, "unit_price": 3990}], "shipping": 1500},
  "1043": {"status": "shipped", "shipped_on": "2026-09-30", "tracking": "BR123456789",
           "lines": [{"sku": "LAMP-02", "quantity": 1, "unit_price": 21000}], "shipping": 0}
}
JSON
put data/stock.json <<'JSON'
{
  "MUG-01": {"in_stock": 37, "unit_price": 3990},
  "LAMP-02": {"in_stock": 4, "unit_price": 21000},
  "GLASS-03": {"in_stock": 0, "unit_price": 2490}
}
JSON
put shop_tools.py <<'PY'
"""The shop's tools: what the model may ask for, and the code that does it."""
import json
from datetime import date
from pathlib import Path

TODAY = date(2026, 10, 2)  # fixed, so the lesson's output does not move
REASONS = ["changed_mind", "wrong_item", "damaged", "faulty"]

TOOLS = [
    {
        "name": "get_stock",
        "description": "Units in stock and unit price in cents for one product, by its SKU.",
        "input_schema": {
            "type": "object",
            "properties": {"sku": {"type": "string", "description": "The product's SKU, such as MUG-01."}},
            "required": ["sku"],
        },
    },
    {
        "name": "create_return",
        "description": "Open a return for units of one line of a delivered order. "
                       "Use it only when the customer has asked to return something.",
        "input_schema": {
            "type": "object",
            "properties": {
                "order_id": {"type": "string", "pattern": "^[0-9]{4}$", "description": "Such as 1042."},
                "sku": {"type": "string", "description": "The SKU as it appears on the order line."},
                "quantity": {"type": "integer", "minimum": 1},
                "reason": {"type": "string", "enum": REASONS},
            },
            "required": ["order_id", "sku", "quantity", "reason"],
            "additionalProperties": False,
        },
    },
]


class ShopError(Exception):
    """A request the shop refuses. The message is written for the model to read."""


def get_stock(sku):
    stock = json.loads(Path("data/stock.json").read_text())
    if sku not in stock:
        raise ShopError(f"no product {sku}; SKUs look like MUG-01")
    return stock[sku]


def create_return(order_id, sku, quantity, reason):
    orders = json.loads(Path("data/orders.json").read_text())
    order = orders.get(order_id)
    if order is None:
        raise ShopError(f"no order {order_id}")
    if order["status"] != "delivered":
        raise ShopError(f"order {order_id} is {order['status']}, not delivered; it cannot be returned yet")
    days = (TODAY - date.fromisoformat(order["delivered_on"])).days
    if days > 30:
        raise ShopError(f"order {order_id} was delivered {days} days ago; returns close after 30")
    bought = sum(line["quantity"] for line in order["lines"] if line["sku"] == sku)
    path = Path("data/returns.json")
    returns = json.loads(path.read_text()) if path.exists() else []
    taken = sum(r["quantity"] for r in returns if r["order_id"] == order_id and r["sku"] == sku)
    if quantity > bought - taken:
        raise ShopError(f"order {order_id} has {bought - taken} of {sku} left to return, not {quantity}")
    record = {"id": f"R-{order_id}-{len(returns) + 1}", "order_id": order_id, "sku": sku,
              "quantity": quantity, "reason": reason}
    path.write_text(json.dumps(returns + [record], indent=1) + "\n")
    return record


FUNCTIONS = {"get_stock": get_stock, "create_return": create_return}
PY
put stock.py <<'PY'
"""One question, with tools: every request and reply of the round trip, printed."""
import json
import sys

import anthropic

from shop_tools import FUNCTIONS, TOOLS

model = anthropic.Anthropic()
messages = [{"role": "user", "content": sys.argv[1]}]
while True:
    r = model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
    print("<- stop_reason:", r.stop_reason)
    for b in r.content:
        print("  ", json.dumps(b.model_dump(exclude_none=True)))
    messages.append({"role": "assistant", "content": r.content})
    if r.stop_reason != "tool_use":
        break
    results = []
    for b in r.content:
        if b.type == "tool_use":
            out = FUNCTIONS[b.name](**b.input)
            results.append({"type": "tool_result", "tool_use_id": b.id, "content": json.dumps(out)})
    print("-> user:")
    for x in results:
        print("  ", json.dumps(x))
    messages.append({"role": "user", "content": results})
PY

block the-round-trip
on 'python stock.py "Is LAMP-02 in stock?"'

put check_args.py <<'PY'
"""Check a tool call's arguments against the tool's own schema, and list every problem."""
import json
import sys

from jsonschema import Draft202012Validator

from shop_tools import TOOLS

SCHEMAS = {t["name"]: t["input_schema"] for t in TOOLS}


def problems(name, args):
    v = Draft202012Validator(SCHEMAS[name])
    return [f"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}"
            for e in sorted(v.iter_errors(args), key=lambda e: list(map(str, e.path)))]


if __name__ == "__main__":
    for p in problems(sys.argv[1], json.loads(sys.argv[2])) or ["ok"]:
        print(p)
PY

block schemas
on "python check_args.py create_return '{\"order_id\": 1042, \"sku\": \"MUG-01\", \"quantity\": 1, \"reason\": \"customer changed their mind\"}'"
on "python check_args.py create_return '{\"order_id\": \"1042\", \"sku\": \"MUG-01\", \"quantity\": 0, \"note\": \"box unopened\"}'"
on "python check_args.py create_return '{\"order_id\": \"1042\", \"sku\": \"MUG-01\", \"quantity\": 1, \"reason\": \"changed_mind\"}'"

put returns.py <<'PY'
"""A host that checks every call before it runs it, and tells the model what was wrong."""
import json
import sys

import anthropic

from check_args import problems
from shop_tools import FUNCTIONS, TOOLS, ShopError

model = anthropic.Anthropic()


def run(name, args):
    """The text to send back, and whether it is an error."""
    found = problems(name, args)
    if found:
        return "invalid arguments: " + "; ".join(found), True
    try:
        return json.dumps(FUNCTIONS[name](**args)), False
    except ShopError as e:
        return str(e), True


messages = [{"role": "user", "content": sys.argv[1]}]
for step in range(1, 5):
    r = model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
    messages.append({"role": "assistant", "content": r.content})
    results = []
    for b in r.content:
        if b.type == "text":
            print(f"[{step}] model:  {b.text}")
        elif b.type == "tool_use":
            text, error = run(b.name, b.input)
            print(f"[{step}] call:   {b.name}({json.dumps(b.input)})")
            print(f"[{step}] {'error' if error else 'result'}:  {text}")
            results.append({"type": "tool_result", "tool_use_id": b.id, "content": text, "is_error": error})
    if not results:
        break
    messages.append({"role": "user", "content": results})
PY

block validating-arguments
on 'python returns.py "Please return one mug from order 1042, the customer changed their mind."'
on 'cat data/returns.json'
on "python -c 'from shop_tools import create_return; create_return(\"1042\", \"MUG-01\", 2, \"changed_mind\")' 2>&1 | tail -n 1"
on "python -c 'from shop_tools import create_return; create_return(\"1043\", \"LAMP-02\", 1, \"faulty\")' 2>&1 | tail -n 1"

block parallel-calls
on 'python stock.py "Are MUG-01 and GLASS-03 in stock?"'

put one_result.py <<'PY'
"""The mistake: the model asked for two calls and the host sends back one result."""
import anthropic

from shop_tools import TOOLS

model = anthropic.Anthropic()
messages = [{"role": "user", "content": "Are MUG-01 and GLASS-03 in stock?"}]
r = model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
calls = [b for b in r.content if b.type == "tool_use"]
messages += [
    {"role": "assistant", "content": r.content},
    {"role": "user", "content": [{"type": "tool_result", "tool_use_id": calls[0].id, "content": "37"}]},
]
try:
    model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
PY
on 'python one_result.py'

put data/emails/1.txt <<'TXT'
Hello, I got order 1042 last week. I'd like to return one of the two mugs:
it's unused and still in its box. How do I do that? Thanks, Marta
TXT
put data/emails/2.txt <<'TXT'
Hi. My lamp from order 1043 shipped on 30 September and the tracking has had
no update since. I need it for Saturday. Can you check? João
TXT
put extract.py <<'PY'
"""Turn a customer's email into a ticket the support queue can sort, or say it could not."""
import json
import sys
from pathlib import Path

import anthropic
from jsonschema import Draft202012Validator

TICKET = {
    "type": "object",
    "properties": {
        "order_id": {"type": ["string", "null"], "pattern": "^[0-9]{4}$"},
        "category": {"enum": ["return", "delivery", "payment", "warranty", "other"]},
        "summary": {"type": "string", "maxLength": 120},
        "urgent": {"type": "boolean"},
    },
    "required": ["order_id", "category", "summary", "urgent"],
    "additionalProperties": False,
}
SYSTEM = ("Extract the ticket from the customer's email. Reply with one JSON object and "
          "nothing else, matching this JSON Schema:\n" + json.dumps(TICKET))
model = anthropic.Anthropic()


def problems(text):
    try:
        ticket = json.loads(text)
    except json.JSONDecodeError as e:
        return None, [f"not JSON: {e.msg}"]
    found = [f"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}"
             for e in Draft202012Validator(TICKET).iter_errors(ticket)]
    return ticket, found


def extract(email, attempts=2):
    messages = [{"role": "user", "content": email}]
    for attempt in range(1, attempts + 1):
        r = model.messages.create(model="scripted-1", max_tokens=300, system=SYSTEM, messages=messages)
        text = r.content[0].text
        ticket, found = problems(text)
        if not found:
            return ticket
        print(f"attempt {attempt}: {'; '.join(found)}", file=sys.stderr)
        messages += [
            {"role": "assistant", "content": text},
            {"role": "user", "content": "That reply is not valid: " + "; ".join(found)
                                        + ". Reply again with the corrected JSON only."},
        ]
    return None


ticket = extract(Path(sys.argv[1]).read_text())
print(json.dumps(ticket) if ticket else "no valid ticket; this email goes to a person")
PY

block structured-output
on 'python extract.py data/emails/1.txt'
on "python -c 'import anthropic.types as t; print(sorted(t.OutputConfigParam.__annotations__)); print(sorted(t.JSONOutputFormatParam.__annotations__)); print(\"strict\" in t.ToolParam.__annotations__)'"
on "python -c 'import anthropic; anthropic.Anthropic().messages.create(model=\"scripted-1\", max_tokens=50, messages=[{\"role\": \"user\", \"content\": \"hi\"}], output_config={\"format\": {\"type\": \"json_schema\", \"schema\": {\"type\": \"object\"}}})' 2>&1 | tail -n 1"

block repair
on 'python extract.py data/emails/2.txt'

put retry.py <<'PY'
"""The same call run twice, as a host that retries after a timeout would."""
from shop_tools import create_return

args = {"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
for attempt in (1, 2):
    print(attempt, create_return(**args))
PY

block side-effects
lab exec ana 'git add shop_tools.py retry.py && git commit -q -m "Tools for the model"'
on 'rm data/returns.json; python retry.py'
on 'cat data/returns.json'
lab exec ana "python - <<'EOF'
from pathlib import Path
p = Path('shop_tools.py')
s = p.read_text()
s = s.replace('def create_return(order_id, sku, quantity, reason):', 'def create_return(order_id, sku, quantity, reason, *, key):')
s = s.replace('''    returns = json.loads(path.read_text()) if path.exists() else []
''', '''    returns = json.loads(path.read_text()) if path.exists() else []
    for r in returns:
        if r[\"key\"] == key:
            return r  # this exact call already ran: answer as it did then
''')
s = s.replace('''\"quantity\": quantity, \"reason\": reason}''', '''\"quantity\": quantity, \"reason\": reason, \"key\": key}''')
p.write_text(s)
EOF"
lab exec ana "sed -i 's/print(attempt, create_return(\*\*args))/print(attempt, create_return(**args, key=\"toolu_lab_0007_1\"))/' retry.py"
on 'git diff'
on 'rm data/returns.json; python retry.py'
on 'cat data/returns.json'

put openai_stock.py <<'PY'
"""The same round trip through OpenAI's chat completions: the arguments arrive as a string."""
import json
import sys

import openai

from shop_tools import FUNCTIONS, TOOLS

tools = [{"type": "function", "function": {"name": t["name"], "description": t["description"],
                                           "parameters": t["input_schema"]}} for t in TOOLS]
client = openai.OpenAI()
messages = [{"role": "user", "content": sys.argv[1]}]
while True:
    r = client.chat.completions.create(model="scripted-1", messages=messages, tools=tools)
    choice = r.choices[0]
    print("<- finish_reason:", choice.finish_reason)
    messages.append(choice.message.model_dump(exclude_none=True))
    if not choice.message.tool_calls:
        print("  ", choice.message.content)
        break
    for call in choice.message.tool_calls:
        print("   arguments:", repr(call.function.arguments))
        out = FUNCTIONS[call.function.name](**json.loads(call.function.arguments))
        messages.append({"role": "tool", "tool_call_id": call.id, "content": json.dumps(out)})
PY

block other-apis
on 'python openai_stock.py "Is LAMP-02 in stock?"'
