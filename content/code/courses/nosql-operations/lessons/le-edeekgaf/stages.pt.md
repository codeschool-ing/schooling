---
title: Estágios, e a receita por mês
version: 1
---

O financeiro pede a receita por mês. O primeiro programa que a maioria escreve busca todos os
pedidos e soma na aplicação, que é o hábito do trabalho relacional feito através de um ORM. A
resposta do MongoDB é o **pipeline de agregação**: uma lista de estágios enviada ao servidor, em
que cada estágio recebe um fluxo de documentos e passa adiante um fluxo de documentos, e só a saída
do último estágio atravessa a conexão.

## Os pedidos, de novo

Esta aula usa os 100.000 pedidos da aula 7, gerados pelo `orders.js` que aquela aula mostra
inteiro. Se você manteve o contêiner da aula 7, eles já estão lá. Se não, inicie o `mongo` com
`docker start mongo`, ou crie-o de novo:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

e rode o gerador mais uma vez a partir do diretório em que você o salvou. Ele substitui os produtos
e os pedidos, e remove os índices que a aula 7 construiu:

```
ana@vm:~$ docker cp orders.js mongo:/orders.js
ana@vm:~$ docker exec mongo mongosh --quiet shop /orders.js
100000 orders, 4 products
```

## Quatro estágios

Receita por mês, deixando de fora os pedidos cancelados:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> db.orders.aggregate([
|   { $match: { status: { $ne: "cancelled" } } },
|   { $group: {
|       _id: { $dateToString: { format: "%Y-%m", date: "$ordered_at", timezone: "America/Sao_Paulo" } },
|       orders: { $sum: 1 },
|       revenue: { $sum: "$total" }
|   } },
|   { $sort: { _id: 1 } },
|   { $project: { _id: 0, month: "$_id", orders: 1, revenue: 1 } }
| ])
[
  { orders: 33, revenue: Decimal128('83546.90'), month: '2025-12' },
  { orders: 8450, revenue: Decimal128('17461804.30'), month: '2026-01' },
  { orders: 7618, revenue: Decimal128('15943671.60'), month: '2026-02' },
  { orders: 8479, revenue: Decimal128('17652330.60'), month: '2026-03' },
  { orders: 8178, revenue: Decimal128('17010851.70'), month: '2026-04' },
  { orders: 8403, revenue: Decimal128('17497813.80'), month: '2026-05' },
  { orders: 7928, revenue: Decimal128('16348310.80'), month: '2026-06' },
  { orders: 8539, revenue: Decimal128('17674621.80'), month: '2026-07' },
  { orders: 8441, revenue: Decimal128('17996460.50'), month: '2026-08' },
  { orders: 8189, revenue: Decimal128('16728215.60'), month: '2026-09' },
  { orders: 8445, revenue: Decimal128('17446418.70'), month: '2026-10' },
  { orders: 8087, revenue: Decimal128('17196614.60'), month: '2026-11' },
  { orders: 8168, revenue: Decimal128('17002308.70'), month: '2026-12' }
]
shop> db.orders.countDocuments({ ordered_at: { $lt: ISODate("2026-01-01T03:00:00Z") } })
33
shop> exit
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 170\" role=\"img\" aria-label=\"O pipeline de receita por mês como uma fileira de estágios, com o número de documentos que passa entre eles: 100.000 pedidos entram no $match, 98.958 saem e entram no $group, 13 saem do $group, e os mesmos 13 passam pelo $sort e pelo $project até o cliente.\"><defs><marker id=\"flw8-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><text x=\"60.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">coleção</text><rect x=\"155\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$match</text><text x=\"200.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não cancelados</text><rect x=\"295\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$group</text><text x=\"340.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por mês</text><rect x=\"435\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$sort</text><text x=\"480.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">por mês</text><rect x=\"575\" y=\"40\" width=\"90\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">$project</text><text x=\"620.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">renomeia _id</text><line x1=\"105\" y1=\"65\" x2=\"153\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"129.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100,000</text><line x1=\"245\" y1=\"65\" x2=\"293\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"269.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">98,958</text><line x1=\"385\" y1=\"65\" x2=\"433\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"409.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13</text><line x1=\"525\" y1=\"65\" x2=\"573\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"549.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13</text><line x1=\"620\" y1=\"90\" x2=\"620\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#flw8-ah-paper-dim)\"></line><text x=\"620\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">13 documentos até o cliente</text></svg>", "caption": "O fluxo encolhe no $group, e todo estágio depois dele lida com treze documentos. Só a saída do último estágio atravessa a conexão."}
```

Leia o pipeline de cima para baixo, do jeito que os documentos fluem:

- **`$match`** fica com os documentos que passam num filtro, na mesma linguagem do `find`. 98.958
  dos 100.000 pedidos não estão cancelados.
- **`$group`** reduz o fluxo a um documento por valor de `_id`. Aqui `_id` é uma expressão, o mês de
  `ordered_at` escrito como texto, e cada grupo leva dois acumuladores: `$sum: 1` conta, e
  `$sum: "$total"` soma os totais. A soma de valores `Decimal128` é um `Decimal128`, exato até o
  centavo, e é por isso que a aula 6 guardou dinheiro desse jeito.
- **`$sort`** ordena os grupos por mês. Ele ordena treze documentos, não 100.000, porque vem depois
  do grupo.
- **`$project`** remodela cada documento para quem vai lê-lo: `_id` renomeado para `month`.

Um nome de campo dentro de um estágio é escrito com cifrão, `"$total"`, quando quer dizer "o valor
desse campo no documento que está passando". Sem o cifrão, é uma string literal, e `$sum: "total"`
não soma nada, em silêncio.

## O mês é uma pergunta sobre fuso horário

A resposta tem **treze meses, e o primeiro é `2025-12`**, com 33 pedidos, embora todo pedido tenha
sido feito em 2026 pelo relógio do gerador. O gerador sorteou as datas em UTC. O pipeline pediu o
mês em `America/Sao_Paulo`, três horas atrás, então um pedido feito à 01:00 UTC de 1º de janeiro foi
feito às 22:00 de 31 de dezembro em São Paulo. A contagem abaixo do pipeline confirma: 33 pedidos
caem antes das 03:00 UTC de 1º de janeiro.

Nenhuma das duas respostas está errada. São respostas a duas perguntas diferentes, e o relatório
precisa dizer a qual respondeu. Uma data BSON é um instante sem fuso preso a ele, como a aula 6
mostrou, então **o fuso pertence à consulta**, em todo `$dateToString`, `$month` ou `$dateTrunc` que
transforma um instante numa data do calendário. Deixe o `timezone` de fora e você recebe UTC, que é
o fuso de ninguém no financeiro da loja.
