---
title: Contar em vez de pesar
version: 1
---

Uma data para um conjunto de trabalho, uma release ou os compromissos de um trimestre, depende de quanto o time entrega por semana. Isso pode ser medido em pontos, somando-os, ou em itens, contando-os. **Salve o programa abaixo como `weekly.py`** para comparar os dois nas semanas do time de Billing desde as regras novas.

```schooling-example
{
  "language": "python",
  "file": "weekly.py",
  "parts": [
    {
      "code": "\"\"\"weekly.py: what the team finished each week, counted in items and in points.\"\"\"\nimport csv\nimport statistics\nfrom datetime import date, timedelta\n\nitems = [i for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nmonday = date(2026, 8, 3)\ncounts, points = [], []\nprint(\"week of      items  points\")\nwhile monday + timedelta(days=6) <= date(2026, 9, 30):\n    week = [i for i in items\n            if monday <= date.fromisoformat(i[\"merged\"][:10]) < monday + timedelta(days=7)]\n    counts.append(len(week))\n    points.append(sum(int(i[\"points\"]) for i in week))\n    print(f\"{monday}  {counts[-1]:5}  {points[-1]:6}\")\n    monday += timedelta(days=7)\n",
      "note": "**Toda semana inteira desde as regras novas**, de segunda a domingo: quantos itens foram integrados, e quantos pontos eles somavam."
    },
    {
      "code": "\nfor name, values in ((\"items\", counts), (\"points\", points)):\n    spread = statistics.stdev(values) / statistics.mean(values)\n    print(f\"{name:6} mean {statistics.mean(values):5.1f} a week, varies by {spread:.0%} week to week\")\n",
      "note": "**Quanto cada medida oscila**: o desvio-padrão como fração da média, o *coeficiente de variação*. Uma medida mais estável de semana para semana é a melhor base para uma previsão."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 weekly.py
week of      items  points
2026-08-03     13      23
2026-08-10      7      25
2026-08-17     10      30
2026-08-24      8      17
2026-08-31      8      25
2026-09-07      6      13
2026-09-14      6      13
2026-09-21      6      21
items  mean   8.0 a week, varies by 31% week to week
points mean  20.9 a week, varies by 29% week to week
```

As duas séries são **igualmente ruidosas**: os itens variam 31% de semana para semana e os pontos, 29%. Se pontos medissem o trabalho com mais fidelidade que uma contagem, a linha dos pontos seria mais estável, porque itens grandes e pequenos se compensariam. Não é. **Uma previsão construída a partir de pontos não é mais precisa que uma construída a partir de uma contagem, e a contagem não precisa de reunião.** A semana de 10 de agosto ilustra bem: o menor número de itens de agosto, sete, e um dos maiores de pontos, 25. Nenhum dos dois números previu a semana seguinte.

A primeira semana, com 13 itens, é o sistema antigo escoando, que a aula 1 já encontrou. Uma previsão deixaria as primeiras semanas depois de uma mudança de regras fora do seu histórico; a aula 10 diz como escolher a janela.

## Para a contagem funcionar: dimensione os itens

Contar tem um requisito: um item precisa ser **pequeno o bastante para que o seu tamanho não importe muito**. O teste de costume é uma única pergunta feita quando um item está para ser começado, e ela substitui a reunião de estimativa:

> **"Conseguimos terminar isto dentro do nosso percentil 85?"**

Para o time de Billing em setembro, são oito dias. Se a resposta é sim, o item é começado como está. Se a resposta é não, ou "não temos certeza", o item é quebrado em pedaços que passem cada um no teste. Isso ainda é estimar, mas do tipo mais barato: um sim ou não contra um número que o time já conhece, dado pelas pessoas que vão fazer o trabalho.

Dimensionar os itens também melhora todo o resto do curso. Itens menores esperam menos, ficam menos bloqueados e geram deploys menores, que é o argumento do tamanho do lote das aulas 5 e 7 chegando por outra direção. Os itens de oito pontos da seção anterior foram o grupo mais lento sob os dois conjuntos de regras, e quebrá-los teria encurtado a cauda.

## O que a contagem não faz

Contar supõe que os itens do futuro se parecem com os do passado. Um time prestes a começar um tipo de trabalho que nunca fez, uma integração nova, uma migração, não tem histórico para ele, e uma contagem de itens passados diz pouco. Esse é um dos casos para os quais a última seção desta aula guarda a estimativa.
