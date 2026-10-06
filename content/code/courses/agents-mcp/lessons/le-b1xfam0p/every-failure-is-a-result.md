---
title: Every failure is a result
version: 1
---

`Agent.call` is where a model's request meets the world, and it is written so that every failure the model could do something about comes back as a tool result, and nothing it could not fix is hidden.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "    def call(self, call, seen):\n        \"\"\"(content, is_error) for one tool call. Every way it can fail comes back as an error the model reads.\"\"\"\n        t = self.tools.get(call.name)\n        if t is None:\n            return f\"unknown tool {call.name!r}; the tools are {', '.join(self.tools)}\", True\n",
      "note": "**Five checks, in order**, each returning an error the model reads."
    },
    {
      "code": "        key = (call.name, json.dumps(call.args, sort_keys=True))\n        if key in seen:\n            return \"this exact call was already made in this run; use its result\", True\n        seen.add(key)\n",
      "note": "**Repeats are refused with a reason**, not ended: lesson 3 stopped the run on the first repeat; here the model gets one chance to use the result it already has."
    },
    {
      "code": "        problems = sorted(self.validators[call.name].iter_errors(call.args), key=lambda e: list(e.path))\n        if problems:\n            return \"invalid arguments: \" + \"; \".join(\n                f\"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}\" for p in problems), True\n",
      "note": "**Schema validation, with every problem named.**"
    },
    {
      "code": "        if t.writes and not (self.confirm and self.confirm(call)):\n            return \"refused: this tool changes data and needs a person's confirmation\", True\n",
      "note": "**A write needs a person.** With no `confirm` callback, or one that says no, the function never runs. Lesson 17 builds the callback properly."
    },
    {
      "code": "        try:\n            return json.dumps(t.fn(**call.args), ensure_ascii=False, default=str), False\n        except (LookupError, ValueError) as e:\n            return f\"{type(e).__name__}: {e}\", True\n\n",
      "note": "**Only expected errors are caught.** Anything else propagates and stops the run loudly, as lesson 4 argued."
    },
    {
      "code": "    def record(self, trace, record):\n        trace.append(record)\n        if self.trace_path:\n            with open(self.trace_path, \"a\") as f:\n                f.write(json.dumps(record, ensure_ascii=False) + \"\\n\")\n\n",
      "note": "**The trace is appended as the run goes**, one JSON line per step, so a crash leaves the steps before it on disk."
    },
    {
      "code": "    def stop(self, reason, steps, used, trace):\n        found = [f\"{c['tool']}({json.dumps(c['args'])})\" for r in trace for c in r[\"calls\"] if not c[\"error\"]]\n        handoff = f\"Stopped ({reason}). \" + (f\"Results so far: {'; '.join(found)}.\" if found else \"Nothing found yet.\")\n        return Outcome(\"stopped\", None, handoff, steps, used, trace)",
      "note": "**A stopped run hands over its results**, not its plan: every call that succeeded, by name and arguments."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The ways a single tool call can fail in minagent, in the order Agent.call checks them, and what the model reads for each: an unknown tool name, a call already made in this run, arguments that fail the schema, a write with no confirmation, and a known error raised by the function. Each becomes a tool result marked as an error. Three steps in a row with only errors stop the run.\"><defs><marker id=\"l7fail-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7fail-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"82.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">unknown</text><text x=\"82.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tool</text><path d=\"M82 86 L82 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"160\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">repeat</text><path d=\"M144 63 L160 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M222 86 L222 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"300\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"362.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">schema</text><path d=\"M284 63 L300 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M362 86 L362 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"440\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"502.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">write</text><text x=\"502.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">unconfirmed</text><path d=\"M424 63 L440 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M502 86 L502 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"580\" y=\"40\" width=\"124\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"642.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">LookupError</text><text x=\"642.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ValueError</text><path d=\"M564 63 L580 63\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-wire)\"></path><path d=\"M642 86 L642 130\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l7fail-ah-amber)\"></path><rect x=\"20\" y=\"130\" width=\"684\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tool_result with is_error: true, sent back to the model</text><text x=\"362\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three steps of only errors: stopped (no progress)</text></svg>", "caption": "Five checks, one shape of answer: a result the model can read."}
```

## The refund that did not happen

A customer says one of two copies of *Dracula* in M-1047 arrived damaged and asks for a refund. **The model's steps were written by the course**, including the refund it asks for:

```
ana@lab:~/agents$ python run.py "One of the two copies of Dracula in my order M-1047 arrived damaged. Please refund it."
answered after 4 steps, 2717 tokens
I am sorry the book arrived damaged. I cannot issue the refund myself, so I have passed it to a colleague. Our policy is to replace damaged books at no cost: photograph the copy next to its packaging and send the pictures within 14 days, and you do not need to send it back.
  step 1: model 628 ms, 435 in / 10 out; get_order 0 ms
  step 2: model 566 ms, 558 in / 8 out; search_help 331 ms
  step 3: model 1325 ms, 785 in / 28 out; refund ERROR 0 ms
  step 4: model 2689 ms, 832 in / 61 out
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"
0
```

Step 3 asked for `refund`, and `call` refused it: the tool is declared `writes=True` and `run.py` passes no `confirm` callback. The model, scripted to read the refusal, told the customer a colleague would handle it, and quoted the policy from step 2's search: damaged books are replaced at no cost, with photos within 14 days. The last command confirms nothing was refunded: `0`. **The answer is honest about what the agent could not do**, and the decision that matters went to a person.

## The model that kept guessing

```
ana@lab:~/agents$ python run.py "Track my parcel for order M-1043, please."
stopped after 3 steps, 1425 tokens
Stopped (no progress: 3 steps in a row with only errors). Nothing found yet.
  step 1: model 628 ms, 426 in / 10 out; track_parcel ERROR 0 ms
  step 2: model 649 ms, 465 in / 10 out; track_parcel ERROR 0 ms
  step 3: model 647 ms, 504 in / 10 out; parcel_status ERROR 0 ms
```

The course scripted a model that calls tools that do not exist: `track_parcel` twice, with different arguments so the repeat guard does not catch it, then `parcel_status`. Each call came back `unknown tool`, with the list of tools that do exist. After the third step of nothing but errors, the loop stopped on its own rule, not the step limit, and the outcome says so. `Nothing found yet.` is the honest handoff: no tool ever returned anything.

A real model reading *"the tools are get_order, search_help, find_books, refund"* would very likely call `get_order` next and find the tracking code there. The point of the third stop is the case where it does not.
