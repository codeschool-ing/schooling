---
title: Medir uma pré-seleção grupo a grupo
version: 2
---

Dezesseis perfis mostram o mecanismo e são poucos demais para medir qualquer coisa. A medição é feita
sobre a saída real da pré-seleção em muitas decisões, junto com um rótulo dizendo quais decisões
estavam certas. Aqui essa tabela é o `data/shortlist-v1.csv`: 312 candidatos, a região de cada um, se
um revisor depois os julgou capazes de fazer o trabalho (`good`) e se a pré-seleção os escolheu. **As
contagens foram escritas pelo curso**, para que as métricas tenham algo sobre o que discordar, e este
programa escreve a tabela a partir delas. Salve-o como `~/guard/tools/shortlist.py`:

```python
# shortlist.py: write a table of shortlist decisions, one row per applicant.
#
#   guard shortlist v1|v2 > FILE
#
# THE DECISIONS ARE WRITTEN BY THE COURSE, from the counts below: for each
# region, how many good applicants were shortlisted and passed over, and how
# many who could not do the job were shortlisted and passed over. v1 is the
# shortlist as it was; v2 is after the change lesson 3 discusses.
import csv
import sys

# region: (good shortlisted, good passed over, not good shortlisted, not good passed over)
COUNTS = {
    "v1": {"Sudeste": (96, 24, 16, 64), "Nordeste": (30, 20, 5, 45), "Norte": (3, 3, 1, 5)},
    "v2": {"Sudeste": (96, 24, 16, 64), "Nordeste": (40, 10, 16, 34), "Norte": (4, 2, 2, 4)},
}

out = csv.writer(sys.stdout, lineterminator="\n")
out.writerow(["applicant", "region", "good", "shortlisted"])
n = 0
for region, (tp, fn, fp, tn) in COUNTS[sys.argv[1]].items():
    for good, picked, k in ((1, 1, tp), (1, 0, fn), (0, 1, fp), (0, 0, tn)):
        for _ in range(k):
            n += 1
            out.writerow(["fr-%04d" % n, region, good, picked])
```

E a medição, `~/guard/tools/fairness.py`:

```python
# fairness.py: rates per group in a table of decisions, and the gaps between them.
#
#   guard fairness FILE --group COLUMN [--reference VALUE]
#
# FILE is a CSV with a column `good` (could the person do the job) and a column
# `shortlisted`, both 0 or 1. Every rate is computed inside one group. A group
# with fewer than MINIMUM rows is reported as too small: a handful of people
# is chance, not a measurement.
import argparse
import csv

MINIMUM = 30

p = argparse.ArgumentParser(prog="guard fairness")
p.add_argument("file")
p.add_argument("--group", required=True)
p.add_argument("--reference")
a = p.parse_args()


def rates(rows):
    tp = sum(1 for r in rows if r["good"] and r["shortlisted"])
    fn = sum(1 for r in rows if r["good"] and not r["shortlisted"])
    fp = sum(1 for r in rows if not r["good"] and r["shortlisted"])
    tn = sum(1 for r in rows if not r["good"] and not r["shortlisted"])
    n = len(rows)
    return {"n": n, "base": (tp + fn) / n, "selected": (tp + fp) / n,
            "tpr": tp / (tp + fn), "fpr": fp / (fp + tn), "precision": tp / (tp + fp)}


groups = {}
with open(a.file, newline="") as f:
    for r in csv.DictReader(f):
        r["good"], r["shortlisted"] = int(r["good"]), int(r["shortlisted"])
        groups.setdefault(r[a.group], []).append(r)

print("%-10s %4s  %5s  %8s  %5s  %5s  %9s" % (
    a.group, "n", "base", "selected", "TPR", "FPR", "precision"))
measured = {}
for g, rows in groups.items():
    if len(rows) < MINIMUM:
        print("%-10s %4d  too few to measure (fewer than %d)" % (g, len(rows), MINIMUM))
        continue
    s = measured[g] = rates(rows)
    print("%-10s %4d  %5.2f  %8.2f  %5.2f  %5.2f  %9.2f" % (
        g, s["n"], s["base"], s["selected"], s["tpr"], s["fpr"], s["precision"]))

ref = a.reference or max(measured, key=lambda g: measured[g]["selected"])
print("reference: %s" % ref)
for g, s in measured.items():
    if g == ref:
        continue
    r = measured[ref]
    ratio = s["selected"] / r["selected"]
    print("%s against %s" % (g, ref))
    print("  selection ratio   %.2f%s" % (ratio, "   below the four-fifths line (0.80)"
                                             if ratio < 0.8 else ""))
    for key, name in (("tpr", "TPR gap"), ("fpr", "FPR gap"), ("precision", "precision gap")):
        print("  %-17s %+.2f" % (name, s[key] - r[key]))
```

```
ana@lab:~/guard$ guard shortlist v1 > data/shortlist-v1.csv
ana@lab:~/guard$ head -3 data/shortlist-v1.csv
applicant,region,good,shortlisted
fr-0001,Sudeste,1,1
fr-0002,Sudeste,1,1
ana@lab:~/guard$ guard fairness data/shortlist-v1.csv --group region
region        n   base  selected    TPR    FPR  precision
Sudeste     200   0.60      0.56   0.80   0.20       0.86
Nordeste    100   0.50      0.35   0.60   0.10       0.86
Norte        12  too few to measure (fewer than 30)
reference: Sudeste
Nordeste against Sudeste
  selection ratio   0.62   below the four-fifths line (0.80)
  TPR gap           -0.20
  FPR gap           -0.10
  precision gap     +0.00
```

## Cinco taxas, e a pergunta que cada uma responde

Cada coluna é uma taxa dentro de um grupo, e cada uma responde a uma pergunta diferente:

| coluna | de quem | a pergunta que responde |
|---|---|---|
| `base` | todos do grupo | quantos eram bons: a taxa de base |
| `selected` | todos do grupo | quantos a lista escolheu |
| `TPR` | os bons | dos que podiam fazer o trabalho, quantos foram pré-selecionados |
| `FPR` | os que não eram bons | dos que não podiam, quantos foram pré-selecionados mesmo assim |
| `precision` | os pré-selecionados | dos que o cliente viu, quantos podiam fazer o trabalho |

Leia a linha do Nordeste contra a do Sudeste com essas perguntas em mente.

**Seleção.** 35% dos candidatos do Nordeste são pré-selecionados contra 56% dos do Sudeste, e a razão
entre os dois é 0.62. A *regra dos quatro quintos* marca uma razão abaixo de 0.80 como impacto
adverso. Ela vem de diretrizes que reguladores de emprego dos Estados Unidos publicaram em 1978, e não
é lei no Brasil. Mesmo onde se aplica, é uma regra prática. Ainda assim é o primeiro filtro mais usado,
e 0.62 está bem abaixo dela. Exigir que as taxas de seleção sejam iguais se chama **paridade
demográfica**.

**TPR.** Dos freelancers do Nordeste que podiam fazer o trabalho, 60% foram pré-selecionados; dos do
Sudeste, 80%. A diferença de −0.20 é o bônus de CEP do substituto aparecendo no agregado: um bom
freelancer no Nordeste fica de fora duas vezes mais, 40% contra 20%. Exigir que essa diferença seja
zero se chama **igualdade de oportunidades**.

**Precisão.** 0.86 nas duas. Das pessoas que um cliente vê, a mesma parcela consegue fazer o trabalho,
more onde morar. Exigir isso se chama **paridade preditiva**, e por ela a lista é justa.

Essa última linha é o que torna isto difícil. **Um cliente olhando a precisão vê uma lista justa; um
freelancer olhando a TPR vê uma injusta.** Os dois leem a mesma tabela corretamente. A métrica com que
um relatório abre decide o que o relatório conclui, e essa escolha costuma ser feita sem ninguém
perceber que era uma escolha.

## O grupo que a tabela se recusa a medir

O Norte tem 12 candidatos, e a ferramenta não imprime taxa nenhuma para ele. Com 6 candidatos bons, um
pré-selecionado a mais ou a menos move a TPR em 0.17, então qualquer diferença que ela mostrasse seria
quase toda acaso. O corte de 30 é o mesmo que a análise de itens desta própria plataforma usa antes de
julgar uma questão.

Recusar é melhor do que imprimir um número que ninguém deveria ler, e ainda assim é um achado: **o
grupo medido pior costuma ser o grupo com mais a perder com um modelo ruim**, que é a linha de
representação da seção anterior. O remédio é coletar mais decisões antes de concluir qualquer coisa
sobre o Norte, e não tirar a região do relatório porque a linha dela está vazia.
