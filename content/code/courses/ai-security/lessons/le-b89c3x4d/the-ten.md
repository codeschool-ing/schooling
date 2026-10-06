---
title: The ten, beside the controls of this course
version: 1
---

`data/owasp-llm-2025.json` holds the ten categories. **The names are OWASP's; the one-line meanings and
the mapping to the lab are the course's**, written to connect each name to something you have run:

```
ana@lab:~/guard$ python3 -c "import json; [print(r['id'], '-', r['meaning']) for r in json.load(open('data/owasp-llm-2025.json'))]"
LLM01 - text the developer did not write steers the model
LLM02 - personal data or secrets reach a reply, a log or a provider
LLM03 - a model, dataset or package from somewhere else is not what it claims
LLM04 - the data a model learns or retrieves from was tampered with
LLM05 - a reply is used by other code without being checked
LLM06 - an agent can do more than its task needs
LLM07 - the instructions, or what is hidden in them, reach a client
LLM08 - the store a model retrieves from leaks or is tampered with
LLM09 - a confident answer is false and somebody acts on it
LLM10 - one user or one loop spends without limit
ana@lab:~/guard$ guard owasp
LLM01 Prompt Injection                   guard check-in, guard filter, guard gate
LLM02 Sensitive Information Disclosure   guard redact, guard minimise, guard filter
LLM03 Supply Chain                       guard deps
LLM04 Data and Model Poisoning           NOT COVERED IN THIS LAB
LLM05 Improper Output Handling           guard check-out, guard filter
LLM06 Excessive Agency                   guard gate
LLM07 System Prompt Leakage              canary in guard filter
LLM08 Vector and Embedding Weaknesses    NOT COVERED IN THIS LAB
LLM09 Misinformation                     guard ground
LLM10 Unbounded Consumption              guard ratelimit, guard retry, guard gate --budget
10 categories, 2 with no control in this lab
```

Read the map in three groups.

**The ones about what goes in.** *Prompt injection* (LLM01) is the root that lesson 1 described: a
model reads instructions and material as one stream. No single control removes it, which is why its
row names three: narrowing the input (lesson 9), filtering the output (lesson 5) and gating the tools
(lesson 10). *Supply chain* (LLM03) is about anything that came from somewhere else; the lab covers only
the package names of lesson 2, and a model's own provenance is outside it.

**The ones about what comes out.** *Sensitive information disclosure* (LLM02) is lessons 11 and 12.
*Improper output handling* (LLM05) is lesson 9's schema and lesson 5's chain. *System prompt leakage*
(LLM07) has only the canary, which detects a verbatim leak and nothing else; the stronger defence is
lesson 5's advice not to put anything in a system prompt that would matter if it were read.
*Misinformation* (LLM09) is lesson 2.

**The ones about what the model may do.** *Excessive agency* (LLM06) is lesson 10's manifest, gate and
confirmation. *Unbounded consumption* (LLM10) is every limit in the course: per-user rates in lesson 7,
the retry cap in lesson 9, the call budget in lesson 10.

Each row is a pointer, not a proof. A row with a command in it says the lab has *a* control; whether
that control is enough for a given feature is the question the next section asks.
