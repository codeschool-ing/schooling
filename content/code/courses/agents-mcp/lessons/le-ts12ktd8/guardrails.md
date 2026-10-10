---
title: Guardrails, and when they run
version: 2
---

A **guardrail** in the SDK is a function that checks the input (or the output) of an agent and can stop the run by tripping a wire. It runs beside the agent rather than inside its loop, and it can be plain code or another model call. The one in `oa_guard.py` refuses a message that contains something shaped like a card number, a rule with a right answer that needs no model:

```schooling-example
{
  "language": "python",
  "file": "oa_guard.py",
  "parts": [
    {
      "code": "\"\"\"A guardrail on the customer's message, and a person in front of a refund, with the OpenAI Agents SDK.\"\"\"\nimport asyncio\nimport re\nimport sys\n\nfrom agents import (Agent, GuardrailFunctionOutput, InputGuardrailTripwireTriggered, Runner, input_guardrail,\n                    set_tracing_disabled)\n\nfrom oa_tools import get_order, refund\n\nset_tracing_disabled(True)\n"
    },
    {
      "code": "CARD = re.compile(r\"\\b(?:\\d[ -]?){13,19}\\b\")\n\n\n",
      "note": "**The rule**: 13 to 19 digits, with optional spaces or hyphens between them."
    },
    {
      "code": "def card_check(parallel):\n    @input_guardrail(name=\"no card numbers\", run_in_parallel=parallel)\n",
      "note": "**The same guardrail built two ways**, differing only in `run_in_parallel`."
    },
    {
      "code": "    async def no_card_numbers(ctx, agent, message):\n        \"\"\"Trip if the customer's message contains something shaped like a card number.\"\"\"\n",
      "note": "**A guardrail receives the message** and returns whether the tripwire fired."
    },
    {
      "code": "        await asyncio.sleep(0.5)  # stands for a check that calls a model, which takes time\n        return GuardrailFunctionOutput(output_info=None, tripwire_triggered=bool(CARD.search(str(message))))\n    return no_card_numbers\n\n\n",
      "note": "**A stand-in for a slower check.** Guardrails that call a moderation model take time; half a second of sleep plays that part here, so the timing difference below is visible."
    },
    {
      "code": "def agent(parallel=True):\n    return Agent(name=\"Refunds\", model=\"llama3.2:3b\", tools=[get_order, refund],\n                 input_guardrails=[card_check(parallel)],\n                 instructions=\"You handle refunds in the OpenAI Agents SDK lesson. Look up the order, then refund.\")\n",
      "note": "**The guardrail is attached to the agent**, beside its tools."
    }
  ]
}
```

The same message, with the guardrail in each mode. The recorder's file was removed before each run, and `grep -c` counts the requests that contained the card number. The recorder writes a request down when its reply is complete, even one the program has given up on, so the count waits twenty seconds for the model to finish:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_guard.py parallel "Refund it to my card 4111 1111 1111 1111 please"
refused by the guardrail 'no card numbers'
ana@lab:~/agents$ sleep 20; grep -c 4111 requests.jsonl
1
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_guard.py blocking "Refund it to my card 4111 1111 1111 1111 please"
refused by the guardrail 'no card numbers'
ana@lab:~/agents$ sleep 20; grep -c 4111 requests.jsonl
grep: requests.jsonl: No such file or directory
```

Both runs were refused. **Only one of them kept the card number from leaving the machine.** With `run_in_parallel=True`, the SDK's default, the guardrail and the model request start together; the guardrail took half a second to trip, and by then the request, card number and all, had reached the model: `1`. With `run_in_parallel=False`, the guardrail runs first and the request is never sent: no request at all, so the recorder never even created its file.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two timelines for an input guardrail. Run in parallel, the guardrail and the request to the model start together; the guardrail trips after half a second, but the customer&#x27;s message, card number included, has already been sent to the provider. Run blocking, the guardrail runs first; it trips, and no request is ever sent.\"><defs><marker id=\"l8guard-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8guard-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run_in_parallel=True</text><rect x=\"20\" y=\"46\" width=\"260\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardrail: 0.5 s</text><rect x=\"20\" y=\"88\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request to the model, card number inside</text><path d=\"M284 40 L284 84\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"290\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">trips at 0.5 s: run cancelled, request already sent</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run_in_parallel=False</text><rect x=\"20\" y=\"172\" width=\"260\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">guardrail: 0.5 s</text><rect x=\"300\" y=\"172\" width=\"400\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no request is sent</text><path d=\"M280 189 L300 189\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l8guard-ah-phosphor)\"></path></svg>", "caption": "In parallel, a guardrail can stop the answer. Only blocking can stop the request."}
```

Parallel is the default because it costs no latency when the guardrail passes, which is most of the time. That makes it right for checks whose purpose is to stop a bad *answer*, such as an off-topic request. **For a check whose purpose is to stop data reaching the provider, it is the wrong mode**: by the time it trips, the data is gone. Sensitive data in a customer's message is a privacy problem as well as a security one, and `ai-security` lesson 12 is about what may be sent to a model's provider at all.

Guardrails are not a permission system. A guardrail can refuse an input or an output; it does not decide whether a tool call is allowed, which is what `needs_approval` (section 07) and the host's own checks (lesson 17) are for.
