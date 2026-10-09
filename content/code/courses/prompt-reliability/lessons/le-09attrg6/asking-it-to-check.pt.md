---
title: Pedindo que ele confira
version: 2
---

Autoavaliação é o passo que devolve a resposta de um modelo a ele com uma pergunta: isto está certo?
Parece uma segunda opinião. **É a mesma opinião pedida duas vezes**, e o que ela pode acrescentar
depende inteiramente do que muda entre a primeira leitura e a segunda.

Este prompt de revisão mostra ao modelo a mensagem do cliente e a resposta que ele deu, e pede um
veredito. Salve-o como `prompts/review.txt`:

```
You check answers given by a triage assistant for Folio, an online bookshop.

<message>
{{message|xml}}
</message>

<answer>
{{answer|xml}}
</answer>

Is the answer valid JSON with the right category? Reply OK, or WRONG and the reason.
```

Os dois valores passam pelo `|xml`, como todo valor de fora desde a aula 4: a resposta é texto que o
modelo escreveu, e a mensagem é texto que um cliente escreveu. O prompt pergunta sobre o formato e a
categoria, e não sobre a urgência, então uma resposta conta como errada aqui quando reprova em
`json`, `fields`, `labels` ou `category`.

## Medindo uma verificação

Uma verificação é um classificador como o prompt de triagem, e é medida do mesmo jeito: contra
rótulos que uma pessoa deu. Este programa manda cada resposta de uma execução pelo `review.txt`, uma
chamada a mais por resposta, e confronta cada veredito com o que o `pl` já sabe sobre a resposta.
Ele imprime cada resposta que foi marcada ou estava de fato errada, com o começo do que o revisor
disse, e depois uma tabela. Salve-o como `selfcheck.py`:

```python
"""selfcheck: ask the model to check each triage answer with prompts/review.txt,
and measure the check against the person's labels."""
import sys

from pl import DEFAULTS, call, judge, read_jsonl, read_prompt, render

params, template = read_prompt("prompts/review.txt")
params = {**DEFAULTS, **params}
rows = read_jsonl(sys.argv[1])
cases = {c["id"]: c for c in read_jsonl(rows[0]["cases"])}
table = {(f, w): 0 for f in (True, False) for w in (True, False)}
for row in rows:
    case = cases[row["case"]]
    check, _ = judge(row, case["expect"])
    wrong = check in ("json", "fields", "labels", "category")
    said = call(render(template, {"message": case["message"], "answer": row["text"]}),
                params)["text"].strip()
    flagged = not said.upper().startswith("OK")
    table[flagged, wrong] += 1
    if flagged or wrong:
        tag = row["case"] + ("#%d" % row["sample"] if row["sample"] else "")
        print("%-6s %-5s %s" % (tag, "wrong" if wrong else "right", " ".join(said.split())[:64]))
print("\n%15s %13s %13s" % ("", "really wrong", "really right"))
print("%-15s %13d %13d" % ("flagged", table[True, True], table[True, False]))
print("%-15s %13d %13d" % ("not flagged", table[False, True], table[False, False]))
flags, mistakes = table[True, True] + table[True, False], table[True, True] + table[False, True]
print("precision %.2f   recall %.2f" % (table[True, True] / flags if flags else 0,
                                         table[True, True] / mistakes if mistakes else 0))
```

O `judge` é a função que o `pl check` usa, então *de fato errada* quer dizer exatamente o que quer
dizer no resto do curso. Um veredito que não começa com `OK` é uma marcação. É a mesma medição que a
aula 13 fez de um modelo julgando duas respostas, e tem a mesma referência. **Uma verificação vale o
quanto concorda com os rótulos que uma pessoa deu**, e a próxima seção lê essa concordância numa
tabela.
