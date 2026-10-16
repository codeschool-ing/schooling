---
title: A dispersão, não a média
version: 1
---

"Nosso tempo de ciclo é de nove dias" soa como uma resposta. Esconde a única parte da resposta de que precisa quem vai planejar em cima dela: **com que frequência um item leva muito mais do que nove dias**. Tempos de ciclo não se espalham por igual em volta da média. A maioria dos itens termina relativamente rápido, alguns levam muito mais, e nada pode levar menos que zero, então a distribuição pende para a direita, com uma cauda longa. Nessa forma, a média é puxada para a cauda e não descreve item nenhum em particular.

**Salve o programa abaixo como `cycle.py`** na sua pasta `delivery`.

```schooling-example
{
  "language": "python",
  "file": "cycle.py",
  "parts": [
    {
      "code": "\"\"\"cycle.py: how long the Billing team's items took, as a distribution.\"\"\"\nimport csv\nimport math\nimport sys\nfrom datetime import date\n\nfirst, last = date.fromisoformat(sys.argv[1]), date.fromisoformat(sys.argv[2])\n\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n",
      "note": "**O mesmo começo do `littles.py`**: um período na linha de comando, e a função que transforma uma coluna em data."
    },
    {
      "code": "\n\ndef percentile(values, p):\n    \"\"\"The smallest value with at least p% of the values at or below it.\"\"\"\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n",
      "note": "**Um percentil por posição mais próxima.** Ordene os valores e pegue o que está a p% do caminho para cima, arredondando para cima. É sempre um valor que de fato aconteceu, e isso o torna fácil de dizer em voz alta: *85% dos itens terminaram em tantos dias ou menos*."
    },
    {
      "code": "\n\ndays = [(when(i[\"merged\"]) - when(i[\"started\"])).days\n        for i in csv.DictReader(open(\"items.csv\"))\n        if i[\"merged\"] and first <= when(i[\"merged\"]) <= last]\n",
      "note": "**Um tempo de ciclo por item integrado no período**, em dias corridos de `started` a `merged`."
    },
    {
      "code": "\nprint(f\"{len(days)} items, cycle time in days\")\nprint(f\"  mean {sum(days) / len(days):.1f}   median {percentile(days, 50)}\"\n      f\"   85th {percentile(days, 85)}   95th {percentile(days, 95)}   max {max(days)}\")\n",
      "note": "**Cinco resumos numa linha**: a média, depois os percentis 50, 85 e 95, depois o mais longo."
    },
    {
      "code": "\nfor low in range(0, max(days) + 1, 5):\n    count = sum(1 for d in days if low <= d < low + 5)\n    print(f\"  {low:2}-{low + 4:<2} {'#' * count}\")\n",
      "note": "**Um histograma em texto**: uma linha a cada cinco dias, um `#` por item. É tosco, e mostra a forma que nenhum número sozinho mostra."
    }
  ]
}
```

## Antes da mudança

```
ana@laptop:~/delivery$ python3 cycle.py 2026-06-01 2026-07-31
52 items, cycle time in days
  mean 19.1   median 18   85th 29   95th 38   max 47
   0-4  ##
   5-9  ########
  10-14 ########
  15-19 ###########
  20-24 ##########
  25-29 ######
  30-34 ###
  35-39 ###
  40-44 
  45-49 #
```

Cinquenta e dois itens foram integrados em junho e julho. Metade deles levou 18 dias ou menos, que é a **mediana**. O percentil 85 é **29**: 85% dos itens terminaram em até 29 dias, e os 15% restantes, cerca de um item em cada sete, levaram mais, até 47.

## Depois dela

```
ana@laptop:~/delivery$ python3 cycle.py 2026-09-01 2026-09-30
30 items, cycle time in days
  mean 5.0   median 4   85th 8   95th 12   max 17
   0-4  ##################
   5-9  ########
  10-14 ###
  15-19 #
```

Em setembro a mediana é **4** dias e o percentil 85, **8**. Olhe o histograma em vez da linha de resumo: o grosso foi para as duas primeiras linhas, e a cauda encurtou mas não sumiu. Um item ainda levou 17 dias. Um time que citasse só a média, 5,0, estaria dizendo a um stakeholder algo que era falso para mais de um quarto dos itens: oito dos trinta levaram mais.

## O número a citar

**Cite um percentil, e diga qual.** O 85 é a escolha comum, por um motivo prático: é alto o bastante para um stakeholder raramente se decepcionar, e baixo o bastante para um item excepcional não defini-lo. Dito em voz alta, vira uma promessa sobre o próprio histórico do time: *"85% dos nossos itens terminam em até oito dias."*

O Kanban Guide chama uma afirmação desse formato de **expectativa de nível de serviço**, uma SLE: um tempo de ciclo e a probabilidade de cumpri-lo. Não é uma meta cobrada do time, e não é um prazo para nenhum item específico. É uma previsão, feita a partir do histórico, e a aula 3 a usa toda manhã: um item ainda aberto depois de oito dias já está entre os 15% lentos.

Vale conhecer o percentil 95 também, e vale citá-lo menos. Com trinta itens, o 95 é o segundo item mais longo, então um único retardatário novo o move. **Quanto menos itens no período, menos os percentis altos aguentam**, e cinquenta é um mínimo razoável antes de citar o 95 para qualquer pessoa.

## Para que serve a média

A média não é inútil. É o número em que a lei de Little fala, e a aula 1 a usou exatamente para isso, porque a lei é sobre médias. Ela também é sensível à cauda de propósito: se a média sobe enquanto a mediana fica parada, os itens lentos ficaram mais lentos, e isso vale saber. Onde ela é ruim é em ser repetida para alguém que quer saber quando o seu item vai ficar pronto.
