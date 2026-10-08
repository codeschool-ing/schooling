---
title: The ten, beside the controls of this course
version: 2
---

`data/owasp-llm-2025.json` holds the ten categories. **The names are OWASP's; the one-line meanings and
the mapping to this course's commands are the course's**, written to connect each name to something
you have run or will run. Paste it:

```sh
cat > ~/guard/data/owasp-llm-2025.json <<'EOF'
[
{"id": "LLM01", "name": "Prompt Injection", "meaning": "text the developer did not write steers the model", "controls": ["guard check-in", "guard filter", "guard gate"], "lessons": [9, 5, 10]},
{"id": "LLM02", "name": "Sensitive Information Disclosure", "meaning": "personal data or secrets reach a reply, a log or a provider", "controls": ["guard redact", "guard minimise", "guard filter"], "lessons": [11, 12, 5]},
{"id": "LLM03", "name": "Supply Chain", "meaning": "a model, dataset or package from somewhere else is not what it claims", "controls": ["guard deps"], "lessons": [2]},
{"id": "LLM04", "name": "Data and Model Poisoning", "meaning": "the data a model learns or retrieves from was tampered with", "controls": [], "lessons": []},
{"id": "LLM05", "name": "Improper Output Handling", "meaning": "a reply is used by other code without being checked", "controls": ["guard check-out", "guard filter"], "lessons": [9, 5]},
{"id": "LLM06", "name": "Excessive Agency", "meaning": "an agent can do more than its task needs", "controls": ["guard gate"], "lessons": [10]},
{"id": "LLM07", "name": "System Prompt Leakage", "meaning": "the instructions, or what is hidden in them, reach a client", "controls": ["canary in guard filter"], "lessons": [5]},
{"id": "LLM08", "name": "Vector and Embedding Weaknesses", "meaning": "the store a model retrieves from leaks or is tampered with", "controls": [], "lessons": []},
{"id": "LLM09", "name": "Misinformation", "meaning": "a confident answer is false and somebody acts on it", "controls": ["guard ground"], "lessons": [2]},
{"id": "LLM10", "name": "Unbounded Consumption", "meaning": "one user or one loop spends without limit", "controls": ["guard ratelimit", "guard retry", "guard gate --budget"], "lessons": [7, 9, 10]}
]
EOF
```

The program that prints it beside the controls is `~/guard/tools/owasp.py`:

```python
# owasp.py: the OWASP Top 10 for LLM applications, beside this course's controls.
#
#   guard owasp [--uncovered]
#
# It reads data/owasp-llm-2025.json and prints each category with the
# commands that cover it. --uncovered prints only the ones with none.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard owasp")
p.add_argument("--uncovered", action="store_true")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/owasp-llm-2025.json"), encoding="utf-8") as f:
    rows = json.load(f)

none = 0
for r in rows:
    none += not r["controls"]
    if a.uncovered and r["controls"]:
        continue
    print("%-5s %-34s %s" % (r["id"], r["name"],
                             ", ".join(r["controls"]) or "NOT COVERED IN THIS LAB"))
print("%d categories, %d with no control in this lab" % (len(rows), none))
```

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
