---
title: Components, zones and the flows between them
version: 1
---

Lesson 1 listed the places where text enters Tarefa's assistant. That inventory answers *where*. A
threat model answers a harder question: **what could go wrong on each path text takes through the
application, and what stands in the way of it**. The first twelve lessons each built a defence. This
lesson is how a team decides which defences an application needs before anything goes wrong, and
how it notices the ones still missing.

The method has three steps, and each has a section here:

1. **draw the application** as components and the flows between them;
2. **ask a fixed set of questions** of every flow that matters;
3. **write the answers down** as a register, ranked, with the control or the gap beside each.

## A component lives in a zone

A **component** is anything that holds or handles data: the browser, the web application, the code
that builds prompts, the model, a database, the log. A **zone** is a set of components that trust
each other because the same party runs them and the same people can change them. Tarefa's assistant
has three:

- **internet**: the client's browser and the companies calling Tarefa's API. Tarefa controls
  nothing there;
- **tarefa**: Tarefa's own servers, from the web application to the call log;
- **provider**: the third-party model, run by a company Tarefa has a contract with and no control
  over.

Where two zones meet there is a **trust boundary**. A flow that crosses one is where a threat model
looks first: data leaves the hands of whoever was looking after it, or arrives from somebody nobody
checked.

The application as data, written by the course for an invented company. Paste it:

```sh
cat > ~/guard/data/flows.json <<'EOF'
{
 "components": [
  {"id": "browser", "zone": "internet", "what": "a client's browser"},
  {"id": "partner", "zone": "internet", "what": "a company calling Tarefa's API"},
  {"id": "app", "zone": "tarefa", "what": "Tarefa's web application and API"},
  {"id": "assistant", "zone": "tarefa", "what": "the code that builds prompts and reads replies"},
  {"id": "helpdesk", "zone": "tarefa", "what": "the help centre pages"},
  {"id": "files", "zone": "tarefa", "what": "files clients attach to a job"},
  {"id": "tools", "zone": "tarefa", "what": "the tool runners behind the gate"},
  {"id": "orders", "zone": "tarefa", "what": "the orders database"},
  {"id": "log", "zone": "tarefa", "what": "the call log"},
  {"id": "model", "zone": "provider", "what": "the third-party model"}
 ],
 "flows": [
  {"id": "f1", "from": "browser", "to": "app", "carries": "chat message", "text_from": "client"},
  {"id": "f2", "from": "app", "to": "browser", "carries": "reply", "text_from": "model"},
  {"id": "f3", "from": "partner", "to": "app", "carries": "API request", "text_from": "partner"},
  {"id": "f4", "from": "app", "to": "assistant", "carries": "message and session", "text_from": "client"},
  {"id": "f5", "from": "helpdesk", "to": "assistant", "carries": "retrieved pages", "text_from": "tarefa"},
  {"id": "f6", "from": "files", "to": "assistant", "carries": "attachment text", "text_from": "client"},
  {"id": "f7", "from": "assistant", "to": "model", "carries": "prompt", "text_from": "client"},
  {"id": "f8", "from": "model", "to": "assistant", "carries": "completion", "text_from": "model"},
  {"id": "f9", "from": "assistant", "to": "tools", "carries": "proposed call", "text_from": "model"},
  {"id": "f10", "from": "tools", "to": "orders", "carries": "query", "text_from": "tarefa"},
  {"id": "f11", "from": "assistant", "to": "log", "carries": "prompt and reply", "text_from": "client"},
  {"id": "f12", "from": "browser", "to": "files", "carries": "upload", "text_from": "client"}
 ]
}
EOF
```

Ten components and twelve flows. Each flow names its two ends, what it carries, and **who wrote the
text in it**: the client, a partner, the model, or Tarefa. The program that reads it is short. Save
it as `~/guard/tools/flows.py`:

```python
# flows.py: the assistant's data flows, and the ones a threat model reviews.
#
#   guard flows [--text]
#
# It reads data/flows.json: each component and the zone it runs in, and each
# flow between two components with who wrote the text it carries. A flow
# whose ends sit in different zones crosses a trust boundary and is marked
# for review. With --text, so is a flow that carries text Tarefa did not
# write, wherever it runs.
import argparse
import json
import os
import sys

p = argparse.ArgumentParser(prog="guard flows")
p.add_argument("--text", action="store_true")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/flows.json"), encoding="utf-8") as f:
    model = json.load(f)
zone = {c["id"]: c["zone"] for c in model["components"]}
for fl in model["flows"]:
    for end in (fl["from"], fl["to"]):
        if end not in zone:
            sys.exit("flows: %s names %s, which is not a component" % (fl["id"], end))


def review(fl):
    """Why a flow needs a threat model's attention, or None."""
    a_zone, b_zone = zone[fl["from"]], zone[fl["to"]]
    if a_zone != b_zone:
        return "crosses %s -> %s" % (a_zone, b_zone)
    if a.text and fl["text_from"] != "tarefa":
        return "carries %s text" % fl["text_from"]
    return None


marked = 0
print("%-4s %-10s %-10s %-22s %s" % ("flow", "from", "to", "carries", "review"))
for fl in model["flows"]:
    why = review(fl)
    marked += why is not None
    print("%-4s %-10s %-10s %-22s %s" % (fl["id"], fl["from"], fl["to"], fl["carries"], why or "-"))
print("%d flows, %d marked for review" % (len(model["flows"]), marked))
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Tarefa's assistant as a data-flow diagram: ten components in three zones, the internet, Tarefa's servers and the model provider, joined by twelve flows. Six flows cross from one zone to another: f1, f2, f3, f7, f8 and f12.\"><defs><marker id=\"dfd-a\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dfd-b\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"22\" width=\"140\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"14\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">internet</text><rect x=\"185\" y=\"22\" width=\"410\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"189\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Tarefa's servers</text><rect x=\"605\" y=\"22\" width=\"110\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"609\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">provider</text><line x1=\"128.0\" y1=\"80.0\" x2=\"202.0\" y2=\"80.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"70.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f1</text><line x1=\"202.0\" y1=\"92.0\" x2=\"128.0\" y2=\"92.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"108.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f2</text><line x1=\"94.1\" y1=\"237.9\" x2=\"235.9\" y2=\"104.1\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f3</text><line x1=\"282.4\" y1=\"103.6\" x2=\"367.6\" y2=\"158.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"325.0\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f4</text><line x1=\"395.0\" y1=\"75.0\" x2=\"395.0\" y2=\"157.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"399.0\" y=\"111.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f5</text><line x1=\"308.0\" y1=\"176.0\" x2=\"342.0\" y2=\"176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"325.0\" y=\"171.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f6</text><line x1=\"448.0\" y1=\"170.0\" x2=\"609.0\" y2=\"170.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"528.5\" y=\"160.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f7</text><line x1=\"609.0\" y1=\"182.0\" x2=\"448.0\" y2=\"182.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"528.5\" y=\"198.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f8</text><line x1=\"395.0\" y1=\"195.0\" x2=\"395.0\" y2=\"262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"399.0\" y=\"223.5\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f9</text><line x1=\"448.0\" y1=\"281.0\" x2=\"492.0\" y2=\"281.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"470.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f10</text><line x1=\"421.5\" y1=\"158.3\" x2=\"503.5\" y2=\"103.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"462.5\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f11</text><line x1=\"109.7\" y1=\"103.3\" x2=\"220.3\" y2=\"158.7\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f12</text><rect x=\"25\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">browser</text><rect x=\"25\" y=\"240\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">partner</text><rect x=\"205\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><rect x=\"205\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">files</text><rect x=\"345\" y=\"40\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">helpdesk</text><rect x=\"345\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant</text><rect x=\"345\" y=\"265\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tools</text><rect x=\"480\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">log</text><rect x=\"495\" y=\"265\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><rect x=\"612\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"662\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">model</text><text x=\"12\" y=\"340\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">red: the flow crosses a trust boundary</text></svg>", "caption": "The twelve flows of `data/flows.json`. The dashed boxes are the zones, and a red arrow is a flow `guard flows` marks because its two ends sit in different ones."}
```

Run it:

```
ana@lab:~/guard$ guard flows
flow from       to         carries                review
f1   browser    app        chat message           crosses internet -> tarefa
f2   app        browser    reply                  crosses tarefa -> internet
f3   partner    app        API request            crosses internet -> tarefa
f4   app        assistant  message and session    -
f5   helpdesk   assistant  retrieved pages        -
f6   files      assistant  attachment text        -
f7   assistant  model      prompt                 crosses tarefa -> provider
f8   model      assistant  completion             crosses provider -> tarefa
f9   assistant  tools      proposed call          -
f10  tools      orders     query                  -
f11  assistant  log        prompt and reply       -
f12  browser    files      upload                 crosses internet -> tarefa
12 flows, 6 marked for review
```

Six of the twelve cross a boundary, and each crossing is a sentence a threat model has to be able to
finish. `f1`: a client's message arrives from the internet. `f7`: a prompt leaves for the provider.
`f8`: the provider's completion comes back. `f12`: a file a client chose lands on Tarefa's disk.

## The second lens: who wrote the text

The zone rule misses something, and the miss is the reason this course exists. **`f6` carries the
text of an attachment from Tarefa's own file store to Tarefa's own assistant.** Both ends are in the
same zone, so the rule says nothing. But a client wrote that text, and the model will read it in the
same stream as Tarefa's instructions. Lesson 1 called that the property that makes an LLM
application different: the model cannot reliably tell the instructions it was meant to follow from
instruction-like text inside the material it is working on.

So the program has a second rule, `--text`. A flow that carries text Tarefa did not write is marked
too, wherever it runs:

```
ana@lab:~/guard$ guard flows --text
flow from       to         carries                review
f1   browser    app        chat message           crosses internet -> tarefa
f2   app        browser    reply                  crosses tarefa -> internet
f3   partner    app        API request            crosses internet -> tarefa
f4   app        assistant  message and session    carries client text
f5   helpdesk   assistant  retrieved pages        -
f6   files      assistant  attachment text        carries client text
f7   assistant  model      prompt                 crosses tarefa -> provider
f8   model      assistant  completion             crosses provider -> tarefa
f9   assistant  tools      proposed call          carries model text
f10  tools      orders     query                  -
f11  assistant  log        prompt and reply       carries client text
f12  browser    files      upload                 crosses internet -> tarefa
12 flows, 10 marked for review
```

Ten of twelve now. The four new ones are inside Tarefa's zone and carry somebody else's words: the
client's message on its way to the assistant (`f4`), the attachment (`f6`), the proposed tool call
the model wrote (`f9`), and the log that keeps all of it (`f11`). **In an LLM application the trust
boundary follows the text, not only the network.** A diagram that draws only the servers shows `f6`
as safe, and it is the flow lesson 1 left with no control at all.
