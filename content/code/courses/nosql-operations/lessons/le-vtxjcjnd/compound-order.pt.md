---
title: Índices compostos, e a ordem dos seus campos
version: 1
---

Um índice composto é uma única lista ordenada por vários campos de uma vez: ordenada pelo primeiro
campo, depois, entre valores iguais do primeiro, pelo segundo, e assim por diante. A crença comum é
que ele **ajuda qualquer consulta que mencione os seus campos**. Ele ajuda as consultas que
conseguem usar a sua ordem, e quais são essas depende inteiramente de qual campo vem primeiro.

## Vinte pedidos pendentes, os mais novos primeiro

A tela do depósito mostra os vinte pedidos pendentes mais recentes. Três índices, um de cada vez:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'SORT <- COLLSCAN',
  returned: 20,
  keys: 0,
  docs: 100000,
  ms: 40
}
shop> db.orders.createIndex({ status: 1 })
status_1
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'SORT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 4044,
  docs: 4044,
  ms: 7
}
shop> db.orders.createIndex({ status: 1, ordered_at: -1 })
status_1_ordered_at_-1
shop> summary(db.orders.find({ status: "pending" }).sort({ ordered_at: -1 }).limit(20))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 20,
  docs: 20,
  ms: 2
}
shop> exit
```

| índice | plano | chaves lidas | documentos lidos |
|---|---|---|---|
| nenhum | `SORT <- COLLSCAN` | 0 | 100.000 |
| `{ status: 1 }` | `SORT <- FETCH <- IXSCAN` | 4.044 | 4.044 |
| `{ status: 1, ordered_at: -1 }` | `LIMIT <- FETCH <- IXSCAN` | 20 | 20 |

Com `{ status: 1 }` o índice encontrou todos os 4.044 pedidos pendentes, e então **um estágio
`SORT`** os pôs em ordem de data na memória para ficar com vinte. Um estágio de ordenação é
bloqueante: ele não consegue devolver o primeiro resultado antes de ler a última entrada, então o
custo dele cresce com o número de pedidos pendentes, e não com os vinte da tela. Com
`{ status: 1, ordered_at: -1 }` os pedidos pendentes já estão em ordem de data dentro do índice, a
varredura para depois de vinte, e **não há estágio `SORT` nenhum**.

## Os mesmos dois campos, ao contrário

Troque os campos e peça os pedidos pendentes de março. `hint` faz o servidor usar o índice
indicado, então as duas ordens podem ser comparadas numa só consulta:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> db.orders.createIndex({ ordered_at: -1, status: 1 })
ordered_at_-1_status_1
shop> const march = { status: "pending", ordered_at: { $gte: ISODate("2026-03-01"), $lt: ISODate("2026-04-01") } }

shop> summary(db.orders.find(march).hint({ ordered_at: -1, status: 1 }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 339,
  keys: 8574,
  docs: 339,
  ms: 11
}
shop> summary(db.orders.find(march).hint({ status: 1, ordered_at: -1 }))
{
  stages: 'FETCH <- IXSCAN',
  returned: 339,
  keys: 339,
  docs: 339,
  ms: 2
}
shop> exit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 345\" role=\"img\" aria-label=\"Dois índices nos mesmos dois campos, desenhados como listas ordenadas de cima para baixo. À esquerda, status primeiro: as entradas se agrupam por status, e dentro do grupo pending vão da data mais nova à mais antiga, então os pedidos pendentes de março são um trecho curto, 339 entradas, todas desejadas. À direita, data primeiro: as entradas se agrupam por data, e março é um trecho longo de 8.574 entradas com todos os status misturados, das quais só as 339 pendentes são desejadas.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ status: 1, ordered_at: -1 }</text><rect x=\"60\" y=\"34\" width=\"220\" height=\"22\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"45.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">cancelled</text><rect x=\"60\" y=\"56\" width=\"220\" height=\"120\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">delivered</text><rect x=\"60\" y=\"176\" width=\"220\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"193.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">paid</text><rect x=\"60\" y=\"210\" width=\"220\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">dez … mais novos</text><rect x=\"60\" y=\"236\" width=\"220\" height=\"16\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">março: 339 lidas, 339 usadas</text><text x=\"170\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">jan … mais antigos</text><text x=\"54\" y=\"245.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pending</text><rect x=\"60\" y=\"280\" width=\"220\" height=\"40\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"54\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shipped</text><text x=\"520\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ ordered_at: -1, status: 1 }</text><rect x=\"410\" y=\"34\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"45.916666666666664\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Dez</text><rect x=\"410\" y=\"57.83333333333333\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"69.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Nov</text><rect x=\"410\" y=\"81.66666666666666\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"93.58333333333333\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Out</text><rect x=\"410\" y=\"105.49999999999999\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"117.41666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Set</text><rect x=\"410\" y=\"129.33333333333331\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"141.24999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ago</text><rect x=\"410\" y=\"153.16666666666666\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"165.08333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jul</text><rect x=\"410\" y=\"177.0\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"188.91666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jun</text><rect x=\"410\" y=\"200.83333333333334\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"212.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Mai</text><rect x=\"410\" y=\"224.66666666666669\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"236.58333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Abr</text><rect x=\"410\" y=\"248.50000000000003\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"404\" y=\"260.4166666666667\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Mar</text><line x1=\"418\" y1=\"252.50000000000003\" x2=\"418\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"433\" y1=\"252.50000000000003\" x2=\"433\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"448\" y1=\"252.50000000000003\" x2=\"448\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"463\" y1=\"252.50000000000003\" x2=\"463\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"478\" y1=\"252.50000000000003\" x2=\"478\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"493\" y1=\"252.50000000000003\" x2=\"493\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"508\" y1=\"252.50000000000003\" x2=\"508\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"523\" y1=\"252.50000000000003\" x2=\"523\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"538\" y1=\"252.50000000000003\" x2=\"538\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"553\" y1=\"252.50000000000003\" x2=\"553\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"568\" y1=\"252.50000000000003\" x2=\"568\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"583\" y1=\"252.50000000000003\" x2=\"583\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><line x1=\"598\" y1=\"252.50000000000003\" x2=\"598\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"613\" y1=\"252.50000000000003\" x2=\"613\" y2=\"268.33333333333337\" stroke=\"var(--phosphor)\" stroke-width=\"0.6\"></line><rect x=\"410\" y=\"272.33333333333337\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"284.25000000000006\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Fev</text><rect x=\"410\" y=\"296.1666666666667\" width=\"220\" height=\"23.833333333333332\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404\" y=\"308.08333333333337\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Jan</text><text x=\"520\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">março: 8.574 lidas, 339 usadas</text></svg>", "caption": "A mesma consulta nos mesmos dois campos. Com status primeiro, os pedidos pendentes de março ficam juntos; com data primeiro, eles se espalham por março inteiro, e a varredura lê cada entrada no meio do caminho.", "same": ["Nov", "Jul", "Jun", "Mar", "Jan"]}
```

As duas devolveram 339 pedidos. **`{ ordered_at: -1, status: 1 }` leu 8.574 entradas de índice
para encontrá-los**; `{ status: 1, ordered_at: -1 }` leu 339. No primeiro, o índice está ordenado
por data, e março é um trecho contínuo dele com todos os status misturados: a varredura percorre
todos os pedidos de março e fica com os pendentes. No segundo, os pedidos pendentes são um trecho
contínuo, ordenado por data dentro dele, e março é um pedaço contínuo desse trecho.

## Igualdade, ordenação, intervalo

A regra que sai desses números tem nome na própria documentação do MongoDB: **ponha primeiro os
campos testados por igualdade, depois o campo pelo qual você ordena, depois os campos testados com
um intervalo**. A igualdade estreita o índice a um trecho. Dentro dele, o campo de ordenação já
está em ordem. Um campo de intervalo depois disso é conferido entrada a entrada sem bagunçar a
ordem.

Eis a regra obedecida e quebrada numa mesma consulta: pedidos pendentes de 3.000 ou mais, os vinte
mais novos. Existem 1.139 deles:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> load("/summary.js")
true
shop> const big = { status: "pending", total: { $gte: NumberDecimal("3000") } }

shop> db.orders.countDocuments(big)
1139
shop> db.orders.createIndex({ status: 1, total: 1, ordered_at: -1 })
status_1_total_1_ordered_at_-1
shop> summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, total: 1, ordered_at: -1 }))
{
  stages: 'FETCH <- SORT <- IXSCAN',
  returned: 20,
  keys: 1139,
  docs: 20,
  ms: 4
}
shop> db.orders.createIndex({ status: 1, ordered_at: -1, total: 1 })
status_1_ordered_at_-1_total_1
shop> summary(db.orders.find(big).sort({ ordered_at: -1 }).limit(20).hint({ status: 1, ordered_at: -1, total: 1 }))
{
  stages: 'LIMIT <- FETCH <- IXSCAN',
  returned: 20,
  keys: 73,
  docs: 20,
  ms: 2
}
shop> exit
```

| índice | ordem | plano | chaves lidas |
|---|---|---|---|
| `{ status: 1, total: 1, ordered_at: -1 }` | igualdade, intervalo, ordenação | `FETCH <- SORT <- IXSCAN` | 1.139 |
| `{ status: 1, ordered_at: -1, total: 1 }` | igualdade, ordenação, intervalo | `LIMIT <- FETCH <- IXSCAN` | 73 |

Com o intervalo antes da ordenação, o índice achou barato cada um dos 1.139 pedidos pendentes
grandes, mas eles saem ordenados pelo total, então um estágio `SORT` teve de ler todos para
escolher os vinte mais novos. Com a ordenação antes do intervalo, a varredura percorre os pedidos
pendentes do mais novo para o mais antigo, pula os menores que 3.000 olhando a chave, e para quando
tem vinte: **73 entradas lidas, e nenhuma ordenação**. Ela leu algumas entradas que não queria, o
que parece desperdício no papel e é o plano mais barato, porque a alternativa lê todas e depois
ordena.

Dois detalhes que as tabelas escondem. **A direção só importa quando há dois ou mais campos de
ordenação**: `{ status: 1, ordered_at: -1 }` também atende `sort({ ordered_at: 1 })`, percorrido de
trás para frente, mas um índice em `{ a: 1, b: 1 }` não atende `sort({ a: 1, b: -1 })`. E **um
prefixo de um índice composto também é um índice**: `{ status: 1, ordered_at: -1 }` responde a uma
consulta só em `status`, o que torna `{ status: 1 }` redundante quando o composto existe. A última
seção desta aula conta quanto custa manter os dois.
