---
title: As dez, ao lado dos controles deste curso
version: 2
---

O `data/owasp-llm-2025.json` traz as dez categorias. **Os nomes são da OWASP; os significados de uma
linha e o mapa para os comandos deste curso são do curso**, escritos para ligar cada nome a algo que você
rodou ou vai rodar. Cole o arquivo:

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

O programa que o imprime ao lado dos controles é o `~/guard/tools/owasp.py`:

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

Leia o mapa em três grupos.

**As que tratam do que entra.** *Prompt injection* (LLM01) é a raiz que a aula 1 descreveu: um modelo lê
instruções e material num fluxo só. Nenhum controle sozinho a elimina, e é por isso que a linha dela
nomeia três: estreitar a entrada (aula 9), filtrar a saída (aula 5) e controlar as ferramentas (aula
10). *Supply chain* (LLM03) trata de tudo o que veio de outro lugar; o laboratório cobre só os nomes de
pacote da aula 2, e a procedência do próprio modelo fica fora dele.

**As que tratam do que sai.** *Sensitive information disclosure* (LLM02) são as aulas 11 e 12.
*Improper output handling* (LLM05) é o schema da aula 9 e a cadeia da aula 5. *System prompt leakage*
(LLM07) tem só o canário, que detecta um vazamento literal e mais nada; a defesa mais forte é o conselho
da aula 5 de não pôr num prompt de sistema nada que importe se for lido. *Misinformation* (LLM09) é a
aula 2.

**As que tratam do que o modelo pode fazer.** *Excessive agency* (LLM06) é o manifesto, o portão e a
confirmação da aula 10. *Unbounded consumption* (LLM10) é todo limite do curso: taxas por usuário na
aula 7, o teto de novas tentativas na aula 9, o orçamento de chamadas na aula 10.

Cada linha é um ponteiro, não uma prova. Uma linha com um comando diz que o laboratório tem *um*
controle; se esse controle basta para um dado recurso é a pergunta que a próxima seção faz.
