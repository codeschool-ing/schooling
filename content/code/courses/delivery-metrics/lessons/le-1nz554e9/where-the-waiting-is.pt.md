---
title: Onde a espera realmente acontece
version: 1
---

Um tempo de ciclo diz quanto; não diz onde. A maior parte da vida de um item num quadro é passada **esperando**: alguém começar, um revisor, o próximo deploy. O quadro já registra quando cada item entrou em cada coluna, então a espera pode ser localizada em vez de adivinhada. **Salve o programa abaixo como `stages.py`**; ele lê os dois arquivos que o `billing.py` escreveu.

```schooling-example
{
  "language": "python",
  "file": "stages.py",
  "parts": [
    {
      "code": "\"\"\"stages.py: where an item's lead time went, column by column.\"\"\"\nimport csv\nimport sys\nfrom datetime import date, datetime\n\nfirst, last = date.fromisoformat(sys.argv[1]), date.fromisoformat(sys.argv[2])\nshipped = {}\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    for item in d[\"items\"].split():\n        shipped[item] = datetime.fromisoformat(d[\"at\"])\n",
      "note": "**Quando cada item chegou à produção**, lido do `deploys.csv`: cada deploy lista os itens que levou, então cada item recebe a data e a hora do deploy que o tirou."
    },
    {
      "code": "\ncolumns = {\"backlog\": [], \"development\": [], \"review\": [], \"waiting to deploy\": []}\nfor i in csv.DictReader(open(\"items.csv\")):\n    if i[\"id\"] not in shipped or not first <= shipped[i[\"id\"]].date() <= last:\n        continue\n",
      "note": "**Só itens com deploy no período**, porque o lead time termina na produção, não na integração."
    },
    {
      "code": "    created, started, review = (date.fromisoformat(i[k]) for k in (\"created\", \"started\", \"review\"))\n    merged = datetime.fromisoformat(i[\"merged\"])\n    columns[\"backlog\"].append((started - created).days)\n    columns[\"development\"].append((review - started).days)\n    columns[\"review\"].append((merged.date() - review).days)\n    columns[\"waiting to deploy\"].append((shipped[i[\"id\"]] - merged).total_seconds() / 86400)\n",
      "note": "**Quatro trechos que somam o lead time**: espera no backlog, em desenvolvimento, em revisão, e entre a integração e o deploy. O último é medido em horas e convertido em dias, porque um pipeline diário faz dele uma questão de horas."
    },
    {
      "code": "\nlead = sum(sum(v) for v in columns.values()) / len(columns[\"backlog\"])\nprint(f\"{len(columns['backlog'])} items deployed, average lead time {lead:.1f} days\")\nfor name, values in columns.items():\n    average = sum(values) / len(values)\n    print(f\"  {name:18} {average:5.1f} days  {average / lead:4.0%}\")\n",
      "note": "**A média de cada coluna, e a fatia dela no lead time.** As fatias somam 100%, com a diferença do arredondamento."
    }
  ]
}
```

## Junho e julho

```
ana@laptop:~/delivery$ python3 stages.py 2026-06-01 2026-07-31
51 items deployed, average lead time 42.5 days
  backlog             20.8 days   49%
  development         11.9 days   28%
  review               7.1 days   17%
  waiting to deploy    2.7 days    6%
```

Um item com deploy em junho ou julho esperou, em média, **42,5 dias** do pedido até a produção. Leia as colunas como um conjunto de filas:

- **O desenvolvimento levou 11,9 dias** para itens que precisavam, na mediana, de uns dois dias de trabalho de verdade. Cada dev mantinha até três itens abertos e alternava entre eles, então cada item passava a maior parte do tempo em desenvolvimento esperando o seu dono voltar a ele.
- **A revisão levou 7,1 dias, e quase nada disso foi revisão.** Uma pessoa fazia todas as revisões entre as suas outras tarefas. Uma revisão leva uma ou duas horas; o resto era o item parado numa fila diante da Bia. Esse é o gargalo que o quadro mostrava o tempo todo, e o motivo de o trabalho em andamento ter subido ao longo de julho no gráfico da aula 1.
- **A espera pelo deploy foi de 2,7 dias**, porque o pipeline rodava às quintas: um item integrado numa sexta esperava seis dias por um trem.
- **O backlog foi a maior espera isolada, com 20,8 dias.** O time não conseguia começar pedidos novos mais rápido do que terminava os antigos.

## Setembro

```
ana@laptop:~/delivery$ python3 stages.py 2026-09-01 2026-09-30
30 items deployed, average lead time 32.5 days
  backlog             27.3 days   84%
  development          3.6 days   11%
  review               1.3 days    4%
  waiting to deploy    0.3 days    1%
```

Todas as filas **dentro** do time encolheram. O desenvolvimento caiu de 11,9 dias para 3,6, a revisão de 7,1 para 1,3, a espera pelo deploy de 2,7 dias para algumas horas. O tempo de ciclo do time, desenvolvimento e revisão juntos, caiu de 19 dias para 5.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l02-stages\" aria-label=\"Duas barras empilhadas do lead time médio em dias. Junho e julho: 42,5 dias, sendo 20,8 no backlog, 11,9 em desenvolvimento, 7,1 em revisão e 2,7 esperando o deploy. Setembro: 32,5 dias, sendo 27,3 no backlog, 3,6 em desenvolvimento, 1,3 em revisão e 0,3 esperando o deploy.\"><text x=\"120.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">junho e julho</text><path d=\"M130.0 50.0 L369.2 50.0 L369.2 82.0 L130.0 82.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"249.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20,8</text><path d=\"M369.2 50.0 L506.1 50.0 L506.1 82.0 L369.2 82.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"437.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">11,9</text><path d=\"M506.1 50.0 L587.7 50.0 L587.7 82.0 L506.1 82.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"546.9\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7,1</text><path d=\"M587.7 50.0 L618.8 50.0 L618.8 82.0 L587.7 82.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"626.8\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">42,5 dias</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">setembro</text><path d=\"M130.0 120.0 L443.9 120.0 L443.9 152.0 L130.0 152.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"287.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">27,3</text><path d=\"M443.9 120.0 L485.3 120.0 L485.3 152.0 L443.9 152.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><path d=\"M485.3 120.0 L500.3 120.0 L500.3 152.0 L485.3 152.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><path d=\"M500.3 120.0 L503.7 120.0 L503.7 152.0 L500.3 152.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"511.7\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">32,5 dias</text><path d=\"M130.0 190.0 L144.0 190.0 L144.0 202.0 L130.0 202.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"150.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backlog</text><path d=\"M260.0 190.0 L274.0 190.0 L274.0 202.0 L260.0 202.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"280.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desenvolvimento</text><path d=\"M390.0 190.0 L404.0 190.0 L404.0 202.0 L390.0 202.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"410.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">revisão</text><path d=\"M520.0 190.0 L534.0 190.0 L534.0 202.0 L520.0 202.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"540.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até o deploy</text><text x=\"130.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lead time médio dos itens com deploy no período, por coluna</text></svg>", "caption": "Toda fila dentro do time encolheu, e quem pediu espera só dez dias a menos: o backlog cresceu e ocupou quase todo o ganho.", "same": ["backlog"]}
```

E o lead time de quem pediu caiu só de 42,5 dias para **32,5**. A espera no backlog **subiu**, de 20,8 dias para 27,3, e agora é 84% de tudo o que quem pede espera. Nada deu errado. Pedidos que chegaram em julho, enquanto o time estava entupido, ainda estão na fila; o time agora os termina mais rápido do que antes, mas começou setembro com uns vinte deles esperando, e uma fila de vinte diante de um time que termina um por dia é uma espera de uns vinte dias. A lei de Little de novo, aplicada ao backlog em vez do quadro.

## O que fazer com isso

Essa é a surpresa mais comum quando um time mede o seu lead time pela primeira vez, e a mais útil. **Melhorar o tempo de ciclo é necessário e não é suficiente**: quando o trabalho anda rápido, a maior espera é a que vem antes de alguém começar. Daí saem três movimentos, e nenhum deles é "trabalhar mais rápido":

- **Diga não mais cedo.** Um pedido que não vai ser feito antes de um mês fica melhor recusado, ou adiado explicitamente, do que deixado numa fila onde parece aceito.
- **Mantenha o backlog curto e ordenado.** Um backlog de vinte itens com vazão de um por dia é a promessa de uma espera de três semanas para qualquer coisa nova, a menos que ela fure a fila.
- **Cite os dois relógios.** Um stakeholder que ouviu "nosso tempo de ciclo é de quatro dias" e depois esperou um mês foi enganado, mesmo com cada palavra sendo verdade.
