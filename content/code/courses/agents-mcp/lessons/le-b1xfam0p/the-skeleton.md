---
title: The whole agent in one file
version: 2
---

Lessons 1 to 6 wrote a new loop for every idea: validation in lesson 4, budgets in lesson 5, several agents in lesson 6. Each was short because it carried only that lesson's idea. This lesson puts them together, once, in a module that a real project could start from: `minagent.py`, **183 lines, no framework, nothing hidden**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The four parts of minagent. Tools are built from typed, documented functions with the tool decorator. The agent holds the tools, the limits and the conversation, and runs the loop. It talks to the model only through one method, complete, which AnthropicModel implements for Ollama and a fake model implements in the tests. Every step is written to the trace, and every run ends in an Outcome.\"><defs><marker id=\"l7parts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7parts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l7parts-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">@tool</text><text x=\"30\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">typed functions → schemas</text><rect x=\"260\" y=\"30\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Agent.run</text><text x=\"270\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">budget, guards, conversation</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">complete()</text><text x=\"540\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one method</text><rect x=\"500\" y=\"140\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AnthropicModel</text><text x=\"510\" y=\"171.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ollama or a provider’s API</text><rect x=\"500\" y=\"200\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">FakeModel</text><text x=\"510\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replies the test wrote</text><rect x=\"260\" y=\"150\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">trace.jsonl</text><text x=\"270\" y=\"181.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one line per step</text><rect x=\"20\" y=\"150\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Outcome</text><text x=\"30\" y=\"181.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answered or stopped</text><path d=\"M190 60 L260 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7parts-ah-wire)\"></path><path d=\"M460 60 L530 60\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7parts-ah-amber)\"></path><path d=\"M615 90 L615 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l7parts-ah-phosphor)\" stroke-dasharray=\"4 3\"></path><path d=\"M700 90 L710 90 L710 223 L700 223\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><path d=\"M360 90 L360 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7parts-ah-wire)\"></path><path d=\"M300 90 L300 118 L105 118 L105 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7parts-ah-wire)\"></path></svg>", "caption": "The loop knows nothing about Anthropic; the adapter knows nothing about tools."}
```

It has four parts, and the sections of this lesson take them in order:

| part | what it does | section |
|---|---|---|
| `tool` and `Tool` | turn a typed, documented Python function into a tool definition with a JSON Schema | 03 |
| `Reply` and `AnthropicModel` | put the provider behind one method, `complete`, so nothing else knows the wire | 04 |
| `Agent.run` | the loop: budget, request, guards, results, conversation | 05 |
| `Agent.call`, `record`, `stop` | every way a call fails, the trace, and what a stopped run hands over | 06 to 08 |

`minagent.py` opens with its imports, and each of sections 03 to 06 adds its part below them, in order; put the parts one after another in one file and you have the whole of it:

```python
"""minagent: an agent loop with nothing hidden, in one file.

    from minagent import Agent, AnthropicModel, tool
"""
import inspect
import json
import time
import typing
from dataclasses import dataclass, field

from jsonschema import Draft202012Validator
```

Two smaller files use it. `marginalia.py` declares the shop's four tools with the decorator, and `run.py` runs an agent on a message and prints the outcome and the trace. `test_minagent.py` tests the loop with no model at all (section 09).

## Why write it rather than install one

Lessons 8 to 10 use three vendors' SDKs, and they are worth using. Writing the loop first is not about avoiding them. It is about being able to read them. Every SDK has a tool decorator, a model adapter, a run loop with limits, a way to report errors to the model and a trace. Once you have written each of those you know what to look for in their documentation, and what question to ask when one of them does something surprising.

There is also a plain engineering case for the small version. **A loop you wrote is a loop you can change in an afternoon**: a new guard, a different trace format, a refusal rule. In a framework the same change may mean a plugin interface, a subclass or waiting for a release. The design sheet for this course says the same thing more bluntly: this lesson is the one that does not age, because it depends on no vendor.
