---
title: A idade do item, o número que não chega tarde
version: 1
---

O tempo de ciclo tem uma fraqueza que nenhum cuidado conserta: **ele só é conhecido depois que o item termina**. Um item preso há seis semanas não contribui com nada para tempo de ciclo nenhum até o dia em que finalmente fica pronto, e nesse dia chega ao gráfico de dispersão como uma surpresa que todo mundo poderia ter visto chegar.

A **idade do item** é a medida que não chega tarde. É o número de dias desde que um item aberto foi começado, é conhecida para todo item toda manhã, e cresce um por dia até o item terminar. No dia em que o item termina, a idade vira o seu tempo de ciclo. Então a idade é o tempo de ciclo **enquanto ele ainda está acontecendo**, e isso torna os dois diretamente comparáveis: um item aberto cuja idade passou do percentil 85 dos tempos de ciclo recentes já é mais lento que 85% do que o time terminou ultimamente, aconteça o que acontecer depois.

**Salve o programa abaixo como `age.py`.** Ele recebe uma data, para diante do quadro como ele estava naquela noite e lista cada item aberto com a sua idade.

```schooling-example
{
  "language": "python",
  "file": "age.py",
  "parts": [
    {
      "code": "\"\"\"age.py: how old the open items are, against how long finished ones took.\"\"\"\nimport csv\nimport math\nimport sys\nfrom datetime import date, timedelta\n\ntoday = date.fromisoformat(sys.argv[1])\nitems = list(csv.DictReader(open(\"items.csv\")))\n\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n\n\ndef percentile(values, p):\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n",
      "note": "**O \"hoje\" vem da linha de comando**, então você pode parar diante do quadro em qualquer dia do histórico e vê-lo como o time o via naquele dia. As duas funções auxiliares são as das aulas 1 e 2."
    },
    {
      "code": "\n\nrecent = [(when(i[\"merged\"]) - when(i[\"started\"])).days for i in items\n          if i[\"merged\"] and today - timedelta(days=30) < when(i[\"merged\"]) <= today]\np50, p85 = percentile(recent, 50), percentile(recent, 85)\nprint(f\"finished in the last 30 days: {len(recent)}, median {p50} days, 85th {p85} days\")\nprint(\"  item     column       age\")\n",
      "note": "**A régua é o histórico recente**: os tempos de ciclo dos itens terminados nos 30 dias antes de hoje. A idade de um item aberto é comparada com quanto os itens terminados de fato levaram, não com uma estimativa."
    },
    {
      "code": "\nfor i in items:\n    started, review, merged = when(i[\"started\"]), when(i[\"review\"]), when(i[\"merged\"])\n    if not started or started > today or (merged and merged <= today):\n        continue\n",
      "note": "**Só os itens abertos naquele dia**: começados nele ou antes, e não integrados até então."
    },
    {
      "code": "    column = \"review\" if review and review <= today else \"development\"\n    age = (today - started).days\n    flag = \"past the 85th\" if age > p85 else \"past the median\" if age > p50 else \"\"\n    print(f\"  {i['id']}  {column:12} {age:3}  {flag}\".rstrip())\n",
      "note": "**A idade é o número de dias desde o início do item**, e não para de crescer até ele terminar. A marca diz que parte do histórico recente o item já ultrapassou."
    }
  ]
}
```

## O quadro em 30 de setembro

```
ana@laptop:~/delivery$ python3 age.py 2026-09-30
finished in the last 30 days: 30, median 4 days, 85th 8 days
  item     column       age
  BIL-189  development   40  past the 85th
  BIL-219  review         7  past the median
  BIL-226  development    0
  BIL-227  development    0
  BIL-228  development    0
  BIL-229  review         0
```

Seis itens estão abertos, e um deles é cinco vezes mais velho que o percentil 85. **O `BIL-189` é um bug de um ponto que está aberto há quarenta dias.** É o item que a aula 1 achou pela aritmética, quando o trabalho em andamento de setembro deu um a mais do que os itens terminados explicavam, e que o gráfico de dispersão da aula 2 não conseguia mostrar de jeito nenhum, porque ele não tem ponto. Aqui ele é a primeira linha da saída.

O que aconteceu com ele é banal. Em 21 de agosto o seu dev o começou, descobriu que ele precisava de uma mudança de outro time e o marcou como bloqueado. Um item bloqueado, pela leitura que o próprio time fazia da nova regra, não contava para o limite de um item por dev, então o dev começou outra coisa. Toda daily desde então perguntou a cada pessoa em que ela estava trabalhando, e a resposta honesta nunca incluiu o `BIL-189`.

## O mesmo quadro em 15 de julho

```
ana@laptop:~/delivery$ python3 age.py 2026-07-15
finished in the last 30 days: 26, median 17 days, 85th 31 days
  item     column       age
  BIL-121  review        35  past the 85th
  BIL-123  review        34  past the 85th
  BIL-130  review        27  past the median
  BIL-134  review        22  past the median
  BIL-136  review        20  past the median
  BIL-137  review        19  past the median
  BIL-138  development   16
  BIL-141  development   15
  BIL-142  review        14
  BIL-143  review        13
  BIL-144  review        12
  BIL-145  review        12
  BIL-146  review         9
  BIL-147  development    8
  BIL-148  development    8
  BIL-149  development    8
  BIL-150  development    7
  BIL-151  development    6
  BIL-152  development    6
  BIL-153  development    6
  BIL-154  development    5
  BIL-155  development    5
  BIL-156  development    1
  BIL-157  development    0
  BIL-158  development    0
```

Vinte e cinco itens abertos, e a própria régua é mais longa: mediana de 17 dias e percentil 85 de 31, porque o histórico recente com que ela é comparada também era lento. Mesmo diante dessa régua generosa, **todo item acima da mediana está em revisão**. Os seis itens mais velhos do quadro esperavam todos pela mesma pessoa. A idade aponta para a fila sem que ninguém precise desconfiar dela, que é a mesma descoberta que a aula 2 fez a partir de médias, disponível aqui em qualquer manhã de julho.

## Idade comparada com o quê?

Uma idade só significa alguma coisa ao lado de uma régua, e o programa usa os tempos de ciclo dos itens terminados nos últimos 30 dias. Essa escolha pesa nas duas direções. Uma régua tirada do período lento do time faz tudo parecer normal, como em 15 de julho, quando um item de 31 dias ainda não estava marcado. Uma régua tirada de outro time, ou de uma estimativa, mede o item contra um sistema do qual ele nunca fez parte. **Use o seu próprio histórico recente, e diga qual janela.** Quando o sistema muda, como o do time de Billing mudou em 3 de agosto, a régua leva algumas semanas para acompanhar, e durante essas semanas as marcas são generosas.
