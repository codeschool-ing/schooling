---
title: Exatidão, um erro de cada vez
version: 2
---

A acurácia é o primeiro número que todo mundo relata e o que menos diz. Ela conta as respostas
certas e trata toda resposta errada como o mesmo erro. **Uma matriz de confusão mantém cada erro
separado**: uma linha para cada rótulo que uma pessoa deu, uma coluna para cada rótulo que a resposta
deu. Este programa desenha uma a partir de um arquivo de execução, lendo as respostas do jeito que o
`pl check --lenient` não lê: uma resposta que não é JSON válido, ou que dá um rótulo fora da lista,
vai para uma coluna só dela. Salve-o como `confusion.py`:

```python
"""confusion: every mistake in a run, one cell each, with recall and precision."""
import argparse

from pl import LABELS, parse, read_jsonl

p = argparse.ArgumentParser(prog="confusion")
p.add_argument("run")
p.add_argument("--field", default="category", choices=sorted(LABELS))
a = p.parse_args()

rows = read_jsonl(a.run)
expect = {c["id"]: c["expect"] for c in read_jsonl(rows[0]["cases"])}
labels = LABELS[a.field]
cols = labels + ["(bad)"]
cells = {(e, g): 0 for e in labels for g in cols}
for r in rows:
    got = (parse(r["text"]) or {}).get(a.field)
    cells[expect[r["case"]][a.field], got if got in labels else "(bad)"] += 1

print("%-10s" % "expected" + "".join("%9s" % c for c in cols) + "   recall")
for e in labels:
    total = sum(cells[e, g] for g in cols)
    recall = "%.2f" % (cells[e, e] / total) if total else "-"
    print("%-10s" % e + "".join("%9d" % cells[e, g] for g in cols) + "%9s" % recall)
precision = []
for g in labels:
    total = sum(cells[e, g] for e in labels)
    precision.append("%.2f" % (cells[g, g] / total) if total else "-")
print("%-10s" % "precision" + "".join("%9s" % x for x in precision))
right = sum(cells[e, e] for e in labels)
print("\naccuracy %d/%d = %.2f" % (right, len(rows), right / len(rows)))
```

Ele importa `LABELS` e `parse()` do `pl.py`, então os rótulos e a leitura são os do próprio harness.
Aqui está o `v6-escaped.txt` sobre as setenta mensagens, os quarenta casos do dev e os trinta do
holdout que a aula 5 juntou em `cases/all.jsonl`:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6-all.jsonl
ana@lab:~/triage$ python3 confusion.py runs/v6-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing           4        0        6        5        1        0     0.25
delivery          0        9        5        0        0        0     0.64
returns           0        1       14        0        0        1     0.88
account           0        1        3        9        1        0     0.64
other             0        0        1        0        9        0     0.90
precision      1.00     0.82     0.48     0.64     0.82

accuracy 45/70 = 0.64
```

A diagonal são as respostas certas, 45 de 70. Toda outra célula é um erro específico: linha
`billing`, coluna `returns`, 6, quer dizer que seis mensagens de billing foram classificadas como
returns. `(bad)` guarda as respostas sem rótulo utilizável nenhum, que a próxima seção conta como
formato.

## Revocação e precisão

Os dois números das bordas respondem perguntas diferentes.

**A revocação se lê ao longo de uma linha**: das mensagens que eram mesmo billing, que fatia o
prompt chamou de billing? Quatro de dezesseis, 0,25. Doze mensagens de billing foram para outro
lugar, seis para returns e cinco para account, e a equipe de cobrança nunca vai vê-las a não ser que
alguém as encaminhe.

**A precisão se lê descendo uma coluna**: das mensagens que o prompt chamou de returns, que fatia
era returns? Catorze de vinte e nove, 0,48. Mais da metade dos chamados da equipe de devoluções é
de outra pessoa. Billing tem o formato oposto, precisão 1,00: quando este prompt diz billing, ele
acerta, e diz billing quatro vezes em setenta. **Com este prompt, `returns` é a caixa de tudo do
`llama3.2:3b`**: seis mensagens de billing foram para lá, cinco de entrega e três de conta, e a
matriz diz isso numa coluna onde a acurácia diz só 0,64.

Um prompt pode subir uma baixando a outra. Chamar tudo de billing levaria a revocação de billing a
1,00 e a precisão dele ao chão. É por isso que as duas são relatadas juntas, por rótulo.

## Que erros custam mais

As células não custam o mesmo. A urgência mostra isso melhor:

```
ana@lab:~/triage$ python3 confusion.py runs/v6-all.jsonl --field urgency
expected        low   normal     high    (bad)   recall
low              22        2        0        0     0.92
normal            3        4       22        1     0.13
high              1        0       15        0     0.94
precision      0.85     0.67     0.41

accuracy 41/70 = 0.59
```

Leia a linha `normal`: de trinta mensagens que uma pessoa chamou de normal, o prompt chamou vinte e
duas de high. A revocação de normal é 0,13. Leia a coluna `high`: quarenta e um por cento do que ele
chama de high é high. E a célula que mais custaria, uma mensagem urgente classificada como normal,
tem zero: a revocação de high é 0,94, e a única mensagem urgente que ele perdeu ele chamou de low.

Então este prompt falha na direção barata. Uma equipe de suporte por trás dele acharia a maior parte
da fila marcada como urgente, e aprenderia em uma semana a ignorar o rótulo, o que tem o seu próprio
custo: **um rótulo que todos ignoram não protege ninguém**. A acurácia de urgência é 41 de 70, e
esse número conta uma mensagem urgente perdida exatamente como uma rotineira escalada. Elas não
custam o mesmo. Decida quanto custa cada tipo de erro antes de ler a matriz, e relate as células
caras pelo nome. *Vinte e duas normais classificadas como high, nenhuma high como normal* é uma frase
sobre a qual alguém age; *0,59* não é.
