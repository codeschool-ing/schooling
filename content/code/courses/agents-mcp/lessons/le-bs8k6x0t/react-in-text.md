---
title: ReAct in plain text
version: 1
---

The customer of order M-1047 asks whether the books can still go back and how the refund would work. `react_text.py` answers with text ReAct: the prompt describes two tools and the format, the program keeps a growing transcript, and a regular expression reads each step. **The model's lines in this section were written by the course**, including one it should never have written; the parsing, the tools and their results are real.

```schooling-example
{
  "language": "python",
  "file": "react_text.py",
  "parts": [
    {
      "code": "\"\"\"ReAct in plain text: the model writes Thought and Action lines, and the program parses them.\"\"\"\nimport json\nimport re\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "PROMPT = \"\"\"Answer the customer's question about Marginalia. You can use two tools:\n  get_order[order id]    the order, its lines, and its amounts in cents\n  search_help[words]     the three help-centre articles closest in meaning\nUse this format, one Action at a time:\nThought: what you know and what you need next\nAction: tool[argument]\nObservation: (the program writes the tool's result here)\n... and when you know enough:\nAnswer: the reply to the customer\"\"\"\n",
      "note": "**The tools are described in prose**, with the argument inside square brackets, as in the paper. Nothing checks that the model uses them as described."
    },
    {
      "code": "TOOLS = {\n    \"get_order\": lambda arg: shop.get_order(arg),\n    \"search_help\": lambda arg: [a[\"title\"] + \": \" + a[\"body\"] for a in shop.search_help(arg)],\n}\n",
      "note": "**The program's side**: each name maps to a function of one string."
    },
    {
      "code": "STOP = [\"Observation:\"] if \"--stop\" in sys.argv else []\n\nclient = anthropic.Anthropic()\n",
      "note": "**The flag this section is about.** Run once without it, once with it."
    },
    {
      "code": "transcript = \"Question: \" + sys.argv[1] + \"\\n\"\nfor step in range(1, 6):\n    reply = client.messages.create(model=\"scripted-1\", max_tokens=400, system=PROMPT,\n                                   messages=[{\"role\": \"user\", \"content\": transcript}],\n                                   stop_sequences=STOP)\n    text = reply.content[0].text.rstrip()\n    print(f\"--- step {step} (stop_reason: {reply.stop_reason})\")\n    print(text)\n",
      "note": "**One growing text, sent as a single user message.** Each step appends the model's lines and the real observation."
    },
    {
      "code": "    answer = re.search(r\"^Answer: (.*)\", text, re.M)\n    if answer:\n        break\n    action = re.search(r\"^Action: (\\w+)\\[(.*)\\]\", text, re.M)\n",
      "note": "**The parser.** An `Answer:` line ends the run; otherwise the first `Action:` line is run."
    },
    {
      "code": "    observation = json.dumps(TOOLS[action.group(1)](action.group(2)))\n    print(f\"Observation: {observation[:100]}\")\n    transcript += text + f\"\\nObservation: {observation}\\n\"",
      "note": "**The program writes the Observation line**, with the tool's real result."
    }
  ]
}
```

## The first run, with no stop sequence

```
ana@lab:~/agents$ python react_text.py "Can I still return the books in order M-1047, and how would the refund work?"
--- step 1 (stop_reason: end_turn)
Thought: I need the order's delivery date before I can say anything.
Action: get_order[M-1047]
Observation: {"status": "delivered", "delivered_on": "2026-08-20"}
Thought: It was delivered on 20 August, more than 30 days ago.
Answer: Sorry, order M-1047 can no longer be returned: the 30 days ended on 19 September.
```

The run ended after one step, with a confident answer, and **the answer is wrong**. M-1047 was delivered on 18 September; the lab's calendar says 6 October; the books can still go back until 18 October. Look at where `2026-08-20` came from. The model wrote `Action: get_order[M-1047]` and then, in the same reply, kept going: it wrote an `Observation:` line itself, with a date no tool returned, reasoned from it, and answered. `stop_reason: end_turn` says the model finished of its own accord.

The program never ran `get_order`. Its parser looked for an `Answer:` line first, found one, and stopped, which is exactly what it was written to do. **Nothing was broken except the assumption that the model would wait.**

## The second run, with `stop_sequences=["Observation:"]`

```
ana@lab:~/agents$ python react_text.py "Can I still return the books in order M-1047, and how would the refund work?" --stop
--- step 1 (stop_reason: stop_sequence)
Thought: I need the order's delivery date before I can say anything.
Action: get_order[M-1047]
Observation: {"id": "M-1047", "customer_id": "c-106", "placed_on": "2026-09-15", "status": "delivered", "delivere
--- step 2 (stop_reason: stop_sequence)
Thought: It was delivered on 18 September 2026, so the 30 days run to 18 October. Now the refund rules.
Action: search_help[refund after a return]
Observation: ["When your refund arrives: We refund within three working days of the return reaching our warehouse
--- step 3 (stop_reason: end_turn)
Thought: The order total is 7780 cents with no shipping charge, and refunds go back to the card or account used.
Answer: Yes. Order M-1047 was delivered on 18 September 2026, so both copies can be returned until 18 October. The refund would be 77.80, back to the card or account you paid with, within three working days of the return reaching our warehouse.
```

Same prompt, same rules, one argument different. Each step now ends with `stop_reason: stop_sequence`: generation stopped the moment the model was about to write `Observation:`, so the reply holds a thought and an action and nothing after them. The program ran the tool and wrote the real observation. Step 2 starts from `2026-09-18`, the real date, and step 3 answers with the real total, 7780 cents, as 77.80.

Section 04 says why one argument makes that difference, and why it is not the whole fix.
