---
title: A person before the refund
version: 1
---

`refund` in `oa_tools.py` is declared `@function_tool(needs_approval=True)`. When a model asks for it, the SDK does not run it: the run stops and returns an **interruption**, a pending call waiting for somebody's decision. Lesson 7's `confirm` callback answered the same question inside the loop; here the loop pauses, and the decision can be taken later, by a different process, after a person has looked.

```schooling-example
{
  "language": "python",
  "file": "oa_guard.py",
  "parts": [
    {
      "code": "mode, message = sys.argv[1], sys.argv[2]\nif mode in (\"parallel\", \"blocking\"):\n    try:\n        Runner.run_sync(agent(parallel=mode == \"parallel\"), message)\n    except InputGuardrailTripwireTriggered as e:\n        print(f\"refused by the guardrail {e.guardrail_result.guardrail.get_name()!r}\")\nelse:\n",
      "note": "**Three modes**: the two guardrail modes of section 08, and approve or decline."
    },
    {
      "code": "    result = Runner.run_sync(agent(), message)\n",
      "note": "**The first run ends at the interruption**, not at an answer."
    },
    {
      "code": "    for pending in result.interruptions:\n        print(f\"waiting for approval: {pending.name}({pending.arguments})\")\n",
      "note": "**Each pending call**, with its tool name and the exact arguments the model chose."
    },
    {
      "code": "        state = result.to_state()\n        if mode == \"approve\":\n",
      "note": "**The run's state**, everything needed to continue it. It can be saved and resumed elsewhere."
    },
    {
      "code": "            state.approve(pending)\n        else:\n            state.reject(pending, rejection_message=\"A person declined this refund.\")\n",
      "note": "**The decision is recorded on the state**, approve or reject with a message for the model."
    },
    {
      "code": "        result = Runner.run_sync(agent(), state)\n    print(\"answer:\", result.final_output)",
      "note": "**Running the state continues the run** from the paused call."
    }
  ]
}
```

```
ana@lab:~/agents$ python oa_guard.py approve "One copy in my order M-1047 arrived damaged. Please refund 38.90."
waiting for approval: refund({"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"})
answer: Done: 38.90 has been refunded to your original payment for the damaged copy in order M-1047.
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1047\")[\"refunded\"])"
3890
ana@lab:~/agents$ python oa_guard.py decline "One copy in my order M-1047 arrived damaged. Please refund 38.90."
waiting for approval: refund({"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"})
answer: I could not refund this myself; a colleague will review the damaged copy in order M-1047 and get back to you.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A run with a tool that needs approval. The run stops when the model asks for refund and returns an interruption instead of a final answer. The program shows the pending call to a person, records approve or reject on the run&#x27;s state, and runs the state again. Approved, the refund runs; rejected, the model receives the rejection message as the tool&#x27;s result.\"><defs><marker id=\"l8approve-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8approve-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l8approve-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Runner.run_sync</text><text x=\"30\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">model asks for refund</text><rect x=\"200\" y=\"70\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">result.interruptions</text><text x=\"210\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one pending call</text><rect x=\"390\" y=\"20\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">state.approve()</text><text x=\"400\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refund runs</text><rect x=\"390\" y=\"124\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">state.reject()</text><text x=\"400\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">message to the model</text><rect x=\"580\" y=\"70\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">run_sync(state)</text><text x=\"590\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">continues</text><path d=\"M160 95 L200 95\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-amber)\"></path><path d=\"M350 88 L390 45\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-phosphor)\"></path><path d=\"M350 102 L390 147\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-wire)\"></path><path d=\"M540 45 L580 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-phosphor)\"></path><path d=\"M540 147 L580 105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l8approve-ah-wire)\"></path></svg>", "caption": "The run is paused, not finished, while a person decides."}
```

The person saw exactly what would happen, `refund({"order_id": "M-1047", "cents": 3890, ...})`, before it happened. Approved, the refund ran and `refunded` became 3890. Declined, the refund did not run and the model received the rejection message as the tool's result, so it could tell the customer honestly that a colleague would review it. **The words of both answers were written by the course**; the pause, the state and the two outcomes are the SDK's.

Two details matter for production. The pause can be long: `result.to_state()` can be serialised and the run resumed after a person has answered in a queue hours later, which lesson 7's in-process callback cannot do. And the approval is per call, with its arguments, which is exactly what lesson 17 asks of a confirmation: the person approves this refund of 38.90 on M-1047, not "refunds".
